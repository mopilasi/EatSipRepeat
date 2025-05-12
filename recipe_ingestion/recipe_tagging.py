import os
import re
import time
from tqdm import tqdm
from transformers import pipeline
from .airtable_client import AirtableClient  # Use our client
from .config import AIRTABLE_BASE_ID, AIRTABLE_TABLE_NAME, AIRTABLE_API_KEY # Use our config

# 1️⃣ SET UP AIRTABLE CLIENT
# Uses credentials from config.py which loads .env
# Correct argument order: api_key, base_id, table_name
airtable_client = AirtableClient(AIRTABLE_API_KEY, AIRTABLE_BASE_ID, AIRTABLE_TABLE_NAME)

# 2️⃣ LOAD FREE ZERO-SHOT MODEL
print("Downloading/loading zero-shot classification model...")
# This might take time on the first run as it downloads the model (~1.6 GB)
classifier = pipeline(
    "zero-shot-classification",
    model="facebook/bart-large-mnli",  # Revert back to BART model
    device_map="auto"  # Automatically use GPU if available, otherwise CPU
)
print("Model loaded.")

# --- Tagging Configuration ---
COURSE_LABELS = ["Starter", "Main Course", "Side Dish", "Dessert", "Snack"]

# Keywords for seasonal guessing (simple approach)
SPRING = {"asparagus", "peas", "radish", "fava", "rhubarb", "ramp"}
SUMMER = {"tomato", "corn", "zucchini", "peach", "berry", "melon", "cucumber"}
FALL = {"pumpkin", "squash", "apple", "pear", "cranberry", "fig"}
WINTER = {"kale", "citrus", "sweet potato", "brussels sprout", "pomegranate"} # Added "pomegranate"

# --- Tagging Functions ---

def guess_season(ingredients: str):
    """Simple season guessing based on keyword presence."""
    if not ingredients:
        return ["Unknown"] # Handle cases with no ingredients
    tokens = set(re.findall(r'\b\w+\b', ingredients.lower())) # Extract words

    # Check intersections, can be refined for multi-season items
    if tokens & SPRING: return ["Spring"]
    if tokens & SUMMER: return ["Summer"]
    if tokens & FALL:   return ["Fall"]
    if tokens & WINTER: return ["Winter"]
    return ["Year-Round"] # Default if no specific seasonal keywords found

def guess_diets(ingredients: str):
    """Simple diet guessing based on keyword absence/presence."""
    if not ingredients:
        return ["Unknown"] # Handle cases with no ingredients
        
    ing = ingredients.lower()
    diets = []

    # Define common meat/fish terms
    meat_fish = {"beef", "pork", "lamb", "veal", "chicken", "turkey", "duck", "fish", "salmon", "tuna", "shrimp", "crab", "lobster", "clam", "mussel", "oyster"}
    # Define common dairy/egg terms
    dairy_egg = {"milk", "cheese", "yogurt", "butter", "cream", "egg"}
    # Define common gluten terms
    gluten = {"flour", "bread", "pasta", "wheat", "barley", "rye", "noodle", "dough", "crust"} # Added noodle, dough, crust

    ing_tokens = set(re.findall(r'\b\w+\b', ing))

    is_vegetarian = not bool(ing_tokens & meat_fish)
    is_vegan = is_vegetarian and not bool(ing_tokens & dairy_egg) and "honey" not in ing # Check for dairy/egg/honey

    if is_vegan:
        diets.append("Vegan")
    elif is_vegetarian:
        diets.append("Vegetarian")

    # Check for gluten-free (simplified check)
    if not bool(ing_tokens & gluten):
        diets.append("Gluten-Free Potential") # Use 'Potential' as it's a guess

    return diets if diets else ["Unknown"]

def tag_record(record_data):
    """Generates tags for a single Airtable record."""
    fields = record_data.get("fields", {})
    title = fields.get("Title", "")
    ingredients_raw = fields.get("Ingredients (raw)", "") # Use the raw field

    if not title and not ingredients_raw:
        print(f"Skipping record {record_data.get('id')} due to missing Title and Ingredients.")
        return {"Tagging Status": "Failed - Missing Data"}

    # Concatenate title and ingredients for better context
    text_to_classify = f"Recipe Title: {title}. Ingredients: {ingredients_raw}"

    # 🏷 Course via zero-shot classification
    try:
        # Use multi_label=False if we only want the top course
        classification_result = classifier(text_to_classify, COURSE_LABELS, multi_label=False)
        course = classification_result["labels"][0]
    except Exception as e:
        print(f"Error during classification for record {record_data.get('id')}: {e}")
        course = "Unknown" # Default on error

    # 🏷 Season and Diet via keyword heuristics
    season = guess_season(ingredients_raw)
    diet_tags = guess_diets(ingredients_raw)

    # --- Restore full tagging --- 
    return {
        "Course": course,          # Update Course field
        "Season": season,          # Update Season field (assuming it's multi-select)
        "Diet Tags": diet_tags,    # Update Diet Tags field (assuming it's multi-select)
        "Tagging Status": "Tagged" # Update status
    }
    # --- End Restore ---

# --- Main Execution ---

if __name__ == "__main__":
    print("Starting recipe tagging process...")
    # Get records marked as 'Pending'
    # Note: Adjust maxRecords as needed, or implement pagination in AirtableClient if dealing with >100 pending
    pending_records = airtable_client.get_all_records(
        formula="{Tagging Status}='Pending'" # Correct method name and parameter
    )

    if not pending_records:
        print("No recipes found with 'Pending' status.")
    else:
        print(f"Found {len(pending_records)} recipes to tag.")
        
        tagged_count = 0
        failed_count = 0

        # Use tqdm for progress bar
        for record in tqdm(pending_records, desc="Tagging Recipes"):
            record_id = record.get("id")
            if not record_id:
                print("Skipping record with missing ID.")
                continue

            try:
                # Generate the tags
                update_data = tag_record(record)

                # Update the record in Airtable
                airtable_client.update_record(record_id, update_data)
                
                if update_data.get("Tagging Status") == "Tagged":
                    tagged_count += 1
                else: # Handle specific failure cases if tag_record returns a different status
                     failed_count += 1
                     
            except Exception as e:
                print(f"\nError processing record {record_id}: {e}")
                # Attempt to mark as Failed in Airtable
                try:
                    airtable_client.update_record(record_id, {"Tagging Status": "Failed"})
                except Exception as ae:
                    print(f"  Failed to update status for {record_id}: {ae}")
                failed_count += 1
            
            # Be polite to Airtable API
            time.sleep(0.3) # Slightly increased sleep time

        print(f"\nTagging complete. Successfully tagged: {tagged_count}, Failed: {failed_count}")

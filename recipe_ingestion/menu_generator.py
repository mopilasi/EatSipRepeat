import random
from typing import List, Optional
from .airtable_client import AirtableClient
from .config import AIRTABLE_API_KEY, AIRTABLE_BASE_ID, AIRTABLE_TABLE_NAME

# 1. Initialize Airtable Client
airtable_client = AirtableClient(AIRTABLE_API_KEY, AIRTABLE_BASE_ID, AIRTABLE_TABLE_NAME)

# 2. Define Course Categories for Menu
STARTER_COURSE_TYPES = ["Starter", "Snack", "Side Dish"]
MAIN_COURSE_TYPES = ["Main Course"]
DESSERT_COURSE_TYPES = ["Dessert"]

def fetch_recipes_by_course(course_types: List[str], client: AirtableClient) -> List:
    """
    Fetches all successfully tagged recipes from Airtable that match any of the given course types.
    """
    if not course_types:
        return []

    # Construct the OR part of the formula for course types
    course_conditions = [f"{{Course}}='{ctype}'" for ctype in course_types]
    course_formula_part = f"OR({', '.join(course_conditions)})"
    
    # Combine with Tagging Status
    full_formula = f"AND({course_formula_part}, {{Tagging Status}}='Tagged')"
    
    print(f"Fetching recipes with formula: {full_formula}")
    try:
        records = client.get_all_records(formula=full_formula)
        return records if records else []
    except Exception as e:
        print(f"Error fetching recipes for courses {course_types}: {e}")
        return []

def generate_menu(client: AirtableClient) -> Optional[dict]:
    """
    Generates a 3-course menu (Starter, Main, Dessert) by randomly selecting
    one recipe from each category from Airtable.
    """
    print("\nFetching recipes for each course...")
    starter_recipes = fetch_recipes_by_course(STARTER_COURSE_TYPES, client)
    main_course_recipes = fetch_recipes_by_course(MAIN_COURSE_TYPES, client)
    dessert_recipes = fetch_recipes_by_course(DESSERT_COURSE_TYPES, client)

    print(f"Found {len(starter_recipes)} potential starters.")
    print(f"Found {len(main_course_recipes)} potential main courses.")
    print(f"Found {len(dessert_recipes)} potential desserts.")

    if not starter_recipes:
        print("Error: No starter recipes found (looked for Starter, Snack, or Side Dish). Cannot generate menu.")
        return None
    if not main_course_recipes:
        print("Error: No main course recipes found. Cannot generate menu.")
        return None
    if not dessert_recipes:
        print("Error: No dessert recipes found. Cannot generate menu.")
        return None

    try:
        chosen_starter = random.choice(starter_recipes)
        chosen_main = random.choice(main_course_recipes)
        chosen_dessert = random.choice(dessert_recipes)
    except IndexError:
        # Should not happen if above checks pass, but as a safeguard
        print("Error: Could not select a recipe, a category might have become empty unexpectedly.")
        return None

    return {
        "starter": chosen_starter['fields'], # Return the 'fields' dictionary
        "main": chosen_main['fields'],
        "dessert": chosen_dessert['fields']
    }

# 3. Main execution block for testing
if __name__ == "__main__":
    print("Attempting to generate a 3-course menu...")
    menu = generate_menu(airtable_client)

    if menu:
        print("\n--- Your Generated Menu ---")
        starter_name = menu['starter'].get('Title', 'N/A')
        main_name = menu['main'].get('Title', 'N/A')
        dessert_name = menu['dessert'].get('Title', 'N/A')
        
        print(f"Starter: {starter_name}")
        print(f"Main:    {main_name}")
        print(f"Dessert: {dessert_name}")
        
        # You can print more details if needed, e.g., URLs
        # print(f"Starter URL: {menu['starter'].get('URL', '#')}")
        # print(f"Main URL:    {menu['main'].get('URL', '#')}")
        # print(f"Dessert URL: {menu['dessert'].get('URL', '#')}")
    else:
        print("\nFailed to generate a menu. Please check Airtable for tagged recipes in each category.")

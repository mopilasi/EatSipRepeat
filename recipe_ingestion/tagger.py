import re

class RawDataFormatter:
    def __init__(self):
        pass

    def format_for_airtable(self, scraped_recipe_data):
        """
        Formats the data obtained from the EnhancedScraper (including custom scrapes)
        into the structure required for Airtable, focusing on raw data and
        setting a "Tagging Status".
        """
        if not scraped_recipe_data:
            return None

        # Use keys from the new unified scrape_recipe output
        title = scraped_recipe_data.get("title")
        source_url = scraped_recipe_data.get("url") # Key is now 'url'
        image_url_str = scraped_recipe_data.get("image") # Key is now 'image'
        ingredients_list = scraped_recipe_data.get("ingredients", []) # Key is now 'ingredients'
        instructions_list = scraped_recipe_data.get("instructions", []) # New: Get instructions
        yields = scraped_recipe_data.get("yields") # New: Get yields
        total_time_raw = scraped_recipe_data.get("total_time") # New: Get total_time (raw string)
        host = scraped_recipe_data.get("host") # New: Get host/domain

        # NOTE: Parsing time strings (like '1 hour 30 minutes') into minutes
        # can be complex and is not implemented here. We store the raw string.
        # Similar logic applies to yields (e.g., 'Serves 4-6')

        # Format Image URL for Airtable attachment field
        airtable_image_field = None
        if image_url_str:
            airtable_image_field = [{"url": image_url_str}]

        # Format Ingredients (raw)
        ingredients_raw_string = "\n".join(ingredients_list) if ingredients_list else None # Use newline separator

        # Format Instructions (raw)
        instructions_raw_string = "\n".join(instructions_list) if instructions_list else None # Use newline separator

        # Map to Airtable field names (Update these keys if your Airtable fields differ)
        raw_record = {
            "Title": title,
            "Source URL": source_url,
            "Image URL": airtable_image_field,
            "Ingredients (raw)": ingredients_raw_string,
            "Tagging Status": "Pending",  
            "Approved": False
        }
        
        # Optional: Remove keys with None values before sending to Airtable
        # raw_record = {k: v for k, v in raw_record.items() if v is not None}

        return raw_record

    # --- Methods below are from the old Tagger class and are not currently used by main.py ---
    # --- They can be kept for future use or removed to simplify ---

    def parse_raw_ingredients(self, raw_text):
        """
        Basic parsing of a block of ingredient text into a list of strings.
        This is a very simple example and may need to be more robust.
        """
        if not raw_text:
            return []
        # Simple split by newline, stripping whitespace and removing empty lines
        ingredients = [line.strip() for line in raw_text.split('\n') if line.strip()]
        return ingredients

    def determine_diet_tags(self, recipe_title="", recipe_description="", ingredients_list=None):
        """
        Placeholder for identifying dietary tags (e.g., Vegan, Gluten-Free)
        based on ingredients and other recipe text.
        """
        if ingredients_list is None:
            ingredients_list = []
        diet_tags = []
        if "vegan" in recipe_title.lower() or "vegan" in recipe_description.lower():
            diet_tags.append("Vegan")
        # Add more rules...
        return diet_tags

    def determine_course(self, recipe_title="", recipe_description="", ingredients_list=None):
        """
        Placeholder for determining the course (e.g., Appetizer, Main Course, Dessert)
        """
        if ingredients_list is None:
            ingredients_list = []
        # TODO: Implement logic to infer course.
        if "dessert" in recipe_title.lower() or "cake" in recipe_title.lower() or "cookies" in recipe_title.lower():
            return "Dessert"
        if "appetizer" in recipe_title.lower() or "starter" in recipe_title.lower():
            return "Appetizer"
        # Add more rules...
        return "Unknown"

    def process_recipe_data(self, scraped_data):
        """
        DEPRECATED in the new flow. Kept for reference or potential future use.
        Takes scraped recipe data, processes it, and prepares fields for Airtable.
        """
        # This method used the old structure and assumptions.
        # The new flow uses `format_for_airtable` directly with data from EnhancedScraper.
        print("WARNING: Tagger.process_recipe_data is deprecated for the current main flow.")
        
        title = scraped_data.get("title_guess", "N/A")
        source_url = scraped_data.get("source_url")
        image_url = scraped_data.get("image_url") # Expects a string URL
        raw_ingredients_text = scraped_data.get("raw_ingredients_text")
        
        parsed_ingredients = self.parse_raw_ingredients(raw_ingredients_text)
        
        # Basic course determination
        course = self.determine_course(recipe_title=title, ingredients_list=parsed_ingredients)
        
        # Basic diet tag determination
        diet_tags = self.determine_diet_tags(recipe_title=title, ingredients_list=parsed_ingredients)

        airtable_image_field = None
        if image_url:
            airtable_image_field = [{"url": image_url}]

        processed_data = {
            "Title": title,
            "Source URL": source_url,
            "Image URL": airtable_image_field, 
            "Ingredients (raw)": raw_ingredients_text, 
            "Course": course, 
            "Season": ["Any"], # Placeholder, as a list for multi-select
            "Diet Tags": diet_tags if diet_tags else [], 
            "Prep Time (min)": scraped_data.get("prep_time"), # Placeholder
            "Cook Time (min)": scraped_data.get("cook_time"), # Placeholder
            "Approved": False, 
        }
        return processed_data

# Example Usage (optional)
# if __name__ == '__main__':
#     formatter = RawDataFormatter()
#     sample_scraped_data = {
#         "Title": "Test Chicken Recipe",
#         "Source URL": "http://example.com/chicken",
#         "Image URL": "http://example.com/chicken.jpg",
#         "Ingredients_list": ["1 whole chicken", "1 tbsp olive oil", "salt", "pepper"],
#         "Prep Time (min)": 20,
#         "Cook Time (min)": 75
#     }
#     formatted_record = formatter.format_for_airtable(sample_scraped_data)
#     print("Formatted Airtable Record:", formatted_record)
#
#     # Test old methods (if kept)
#     # ingredients = formatter.parse_raw_ingredients("1 cup flour\n2 eggs\n1 tsp salt")
#     # print("Parsed Ingr:", ingredients)
#     # course = formatter.determine_course(recipe_title="My Dessert Cake")
#     # print("Course:", course)
#     # tags = formatter.determine_diet_tags(recipe_title="Vegan Cookies")
#     # print("Diet Tags:", tags)
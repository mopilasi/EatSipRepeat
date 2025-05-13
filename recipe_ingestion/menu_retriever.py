from typing import List, Dict, Optional

from .airtable_client import AirtableClient
from .config import AIRTABLE_API_KEY, AIRTABLE_BASE_ID

# Initialize Airtable Client for CURATED MENUS table
CURATED_MENUS_TABLE_NAME = "Curated Menus" # Make sure this is the exact name of your Airtable table
curated_menus_client = AirtableClient(AIRTABLE_API_KEY, AIRTABLE_BASE_ID, CURATED_MENUS_TABLE_NAME)

def get_curated_menus_by_season(season: str) -> List[Dict]:
    """
    Fetches all curated menus for a specific season from the "Curated Menus" table.

    Args:
        season: The season to filter menus by (e.g., "Spring", "Summer").

    Returns:
        A list of dictionaries, where each dictionary represents a menu
        with all its details (Name, Starter Name, URL, Description, etc.).
        Returns an empty list if no menus are found or an error occurs.
    """
    fields_to_fetch = [
        "Season", "Menu Name",
        "Starter Name", "Starter URL", "Starter Description",
        "Main Name", "Main URL", "Main Description",
        "Dessert Name", "Dessert URL", "Dessert Description"
    ]
    
    # Ensure the field name for season in the formula matches your Airtable (e.g., {Season})
    formula = f"{{Season}} = '{season}'"
    
    try:
        print(f"Fetching curated menus for {season} with formula: {formula}") # Removed fields for brevity
        menus = curated_menus_client.get_all_records(fields=fields_to_fetch, formula=formula)
        
        if not menus:
            print(f"No curated menus found for season: {season}")
            return []
        
        # The client returns a list of records, each containing an 'id', 'createdTime', and 'fields'
        # We want to return a list of the 'fields' dictionaries
        processed_menus = []
        for menu_record in menus:
            if 'fields' in menu_record:
                processed_menus.append(menu_record['fields'])
            else:
                # This case should ideally not happen if records are found and structured correctly
                print(f"Warning: Record found without 'fields': {menu_record.get('id')}")
        return processed_menus
        
    except Exception as e:
        print(f"Error fetching curated menus for season '{season}': {e}")
        return []

# Example usage (you can run this file directly to test):
if __name__ == '__main__':
    # Make sure you have some data in your "Curated Menus" table for "Spring"
    # or change the season here to one that has data.
    selected_season = "Spring" 
    spring_menus = get_curated_menus_by_season(selected_season)
    
    if spring_menus:
        print(f"\nFound {len(spring_menus)} curated menus for {selected_season}:")
        for i, menu_data in enumerate(spring_menus):
            print(f"\n--- Menu {i+1} ---")
            # Ensure all these keys exist in your 'fields_to_fetch' and Airtable data
            print(f"  Menu Name: {menu_data.get('Menu Name', 'N/A')}")
            print(f"  Season: {menu_data.get('Season', 'N/A')}")
            print(f"  Starter: {menu_data.get('Starter Name', 'N/A')} ({menu_data.get('Starter URL', '#')}) - {menu_data.get('Starter Description', 'No description')}")
            print(f"  Main: {menu_data.get('Main Name', 'N/A')} ({menu_data.get('Main URL', '#')}) - {menu_data.get('Main Description', 'No description')}")
            print(f"  Dessert: {menu_data.get('Dessert Name', 'N/A')} ({menu_data.get('Dessert URL', '#')}) - {menu_data.get('Dessert Description', 'No description')}")
    else:
        print(f"No curated menus to display for {selected_season}. Ensure the table '{CURATED_MENUS_TABLE_NAME}' has entries for this season.")

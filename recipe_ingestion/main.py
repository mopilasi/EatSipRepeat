import sys
from dotenv import load_dotenv
import os
from .scraper import EnhancedScraper
from .tagger import RawDataFormatter
from .airtable_client import AirtableClient

# Load environment variables
load_dotenv()

def ingest_recipes(): 
    """
    Main function to orchestrate the scraping and ingestion process 
    from multiple recipe websites and index pages.
    """
    scraper = EnhancedScraper()
    formatter = RawDataFormatter()
    
    # --- Define index/category URLs for each site ---
    bon_appetit_index_urls = [
        "https://www.bonappetit.com/recipes", 
        "https://www.bonappetit.com/meal-time/dinner", 
        "https://www.bonappetit.com/meal-time/lunch"  
    ]
    smitten_kitchen_index_urls = [
        "https://smittenkitchen.com/recipes/best-of-smitten-kitchen/" 
        # Add more Smitten Kitchen category URLs if desired
    ]
    justine_snacks_index_urls = [
        "https://justinesnacks.com/category/recipes/"
        # Add more Justine Snacks category URLs if desired
    ]

    # --- Get recipe links from all sources ---
    all_recipe_urls_to_scrape = []
    
    # --- Temporarily comment out Bon Appétit scraping ---
    # print("--- Starting Bon Appétit Link Discovery ---")
    # ba_urls = scraper.get_recipe_links_from_index_pages(bon_appetit_index_urls)
    # all_recipe_urls_to_scrape.extend(ba_urls)
    # print(f"--- Bon Appétit Complete: {len(ba_urls)} URLs found ---\n")
    # --- End Bon Appétit comment out ---

    # Call the new Smitten Kitchen function
    sk_urls = scraper.get_recipe_links_from_smitten_kitchen(smitten_kitchen_index_urls)
    all_recipe_urls_to_scrape.extend(sk_urls)
    # Smitten Kitchen function already prints summary

    # Call the new Justine Snacks function
    js_urls = scraper.get_recipe_links_from_justine_snacks(justine_snacks_index_urls)
    all_recipe_urls_to_scrape.extend(js_urls)
    # Justine Snacks function already prints summary

    # Optional: Remove potential duplicates across sites (though unlikely)
    all_recipe_urls_to_scrape = list(set(all_recipe_urls_to_scrape)) 
    
    print(f"\n--- Total Link Discovery Complete: {len(all_recipe_urls_to_scrape)} unique URLs found across all sites ---\n")

    # Rename the variable used in the loop
    recipe_urls_to_scrape = all_recipe_urls_to_scrape 

    if not recipe_urls_to_scrape:
        print("No recipe URLs found from any source. Exiting.")
        return

    # --- Initialize Airtable Client ---
    airtable_api_key = os.getenv("AIRTABLE_API_KEY")
    airtable_base_id = os.getenv("AIRTABLE_BASE_ID")
    airtable_table_name = os.getenv("AIRTABLE_TABLE_NAME")

    if not all([airtable_api_key, airtable_base_id, airtable_table_name]):
        print("Error: Airtable configuration (API Key, Base ID, Table Name) not found in .env file.")
        return
        
    airtable_client = AirtableClient(airtable_api_key, airtable_base_id, airtable_table_name)

    # --- Process Each Recipe URL ---
    print(f"--- Starting Recipe Ingestion for {len(recipe_urls_to_scrape)} URLs ---")
    successful_ingestions = 0
    failed_ingestions = 0
    total_recipes = len(recipe_urls_to_scrape)

    for i, recipe_url in enumerate(recipe_urls_to_scrape):
        print(f"\nProcessing recipe {i+1}/{total_recipes}: {recipe_url}")
        
        # 1. Scrape individual recipe data using the new unified method
        scraped_data = scraper.scrape_recipe(recipe_url)
        
        if not scraped_data:
            print(f"Failed to scrape data for {recipe_url}. Skipping.")
            failed_ingestions += 1
            continue 

        # 2. Format data for Airtable
        try:
            airtable_record_data = formatter.format_for_airtable(scraped_data)
            print(f"Data prepared for Airtable: {airtable_record_data.get('Title', 'N/A')}")
        except Exception as e:
            print(f"Error formatting data for {recipe_url}: {e}")
            failed_ingestions += 1
            continue 

        # 3. Add record to Airtable
        try:
            response = airtable_client.add_record(airtable_record_data)
            if response and 'id' in response: 
                 print(f"Successfully added '{airtable_record_data.get('Title', 'N/A')}' to Airtable.")
                 successful_ingestions += 1
            else:
                 print(f"Failed to add '{airtable_record_data.get('Title', 'N/A')}' to Airtable. Response: {response}")
                 failed_ingestions += 1
        except Exception as e:
            print(f"Error adding record to Airtable: {e}")
            failed_ingestions += 1
            
    # --- Print Summary ---
    print("\n--- Ingestion Summary ---")
    print(f"Total URLs Found: {len(recipe_urls_to_scrape)}") 
    print(f"Successfully ingested: {successful_ingestions}")
    print(f"Failed to ingest: {failed_ingestions}")

# Update the main execution block to call the renamed function
if __name__ == "__main__":
    ingest_recipes() 

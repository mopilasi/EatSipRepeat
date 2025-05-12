import requests
from bs4 import BeautifulSoup
from recipe_scrapers import scrape_me, WebsiteNotImplementedError
from urllib.parse import urljoin, urlparse
import datetime
import re
import time

class EnhancedScraper:
    def __init__(self, default_timeout=10):
        self.default_timeout = default_timeout
        self.headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
        }

    def fetch_html_for_links(self, url):
        try:
            response = requests.get(url, headers=self.headers, timeout=self.default_timeout)
            response.raise_for_status()
            return response.text
        except requests.exceptions.RequestException as e:
            print(f"Error fetching HTML for link discovery from {url}: {e}")
            return None

    def _get_soup(self, url):
        html_content = self.fetch_html_for_links(url)
        if html_content:
            return BeautifulSoup(html_content, 'html.parser')
        return None

    def scrape_recipe(self, url):
        print(f"Scraping individual recipe: {url}")
        domain = urlparse(url).netloc

        try:
            if 'bonappetit.com' in domain:
                scraper = scrape_me(url)
                return {
                    'title': scraper.title(),
                    'yields': scraper.yields(),
                    'ingredients': scraper.ingredients(),
                    'instructions': scraper.instructions_list(),
                    'image': scraper.image(),
                    'host': domain,
                    'total_time': scraper.total_time(),
                    'url': url
                }
            elif 'smittenkitchen.com' in domain:
                soup = self._get_soup(url)
                if soup:
                    return self._scrape_smitten_kitchen(url, soup)
                else:
                    print(f"Failed to get soup for custom scraping: {url}")
                    return None
            elif 'justinesnacks.com' in domain:
                soup = self._get_soup(url)
                if soup:
                    return self._scrape_justine_snacks(url, soup)
                else:
                    print(f"Failed to get soup for custom scraping: {url}")
                    return None
            else:
                print(f"Domain '{domain}' not explicitly supported, trying recipe-scrapers anyway...")
                scraper = scrape_me(url)
                return {
                    'title': scraper.title(),
                    'yields': scraper.yields(),
                    'ingredients': scraper.ingredients(),
                    'instructions': scraper.instructions_list(),
                    'image': scraper.image(),
                    'host': domain,
                    'total_time': scraper.total_time(),
                    'url': url
                }

        except WebsiteNotImplementedError:
            print(f"Website {domain} not supported by recipe-scrapers and no custom parser exists.")
            return None
        except Exception as e:
            print(f"Error during scraping of {url}: {e}")
            return None

    def _scrape_smitten_kitchen(self, url, soup):
        data = {'url': url, 'host': 'smittenkitchen.com'}

        try:
            title_tag = soup.find('h1', class_='entry-title') or soup.find('h1')
            data['title'] = title_tag.get_text(strip=True) if title_tag else None
        except Exception as e:
            print(f"SK: Error parsing title: {e}"); data['title'] = None

        try:
            img_tag = soup.select_one('.entry-content img')
            data['image'] = img_tag['src'] if img_tag else None
        except Exception as e:
            print(f"SK: Error parsing image: {e}"); data['image'] = None

        data['yields'] = None
        data['total_time'] = None
        try:
            recipe_div = soup.find('div', class_='smittenkitchen-recipe') or soup.find('div', class_='entry-content')
            if recipe_div:
                possible_tags = recipe_div.find_all(['p', 'li'])
                for tag in possible_tags:
                    text = tag.get_text(strip=True).lower()
                    if text.startswith('servings:') or text.startswith('yield:'):
                        data['yields'] = tag.get_text(strip=True).split(':', 1)[-1].strip()
                    elif text.startswith('time:'):
                        data['total_time'] = tag.get_text(strip=True).split(':', 1)[-1].strip()
        except Exception as e:
            print(f"SK: Error parsing yield/time: {e}")

        try:
            ingredients_list = []
            recipe_content = soup.find('div', class_='smittenkitchen-recipe') or soup.find('div', class_='entry-content')
            ingredient_section = recipe_content.find_all(['ul', 'ol'])
            found_ingredients = False
            if ingredient_section:
                for section in ingredient_section:
                    items = section.find_all('li')
                    if items:
                        ingredients_list.extend([li.get_text(strip=True) for li in items if li.get_text(strip=True)])
                        found_ingredients = True
            if not found_ingredients:
                print(f"SK: Could not reliably find ingredient list for {url}")
            data['ingredients'] = [i for i in ingredients_list if i]
        except Exception as e:
            print(f"SK: Error parsing ingredients: {e}"); data['ingredients'] = []

        try:
            instructions_list = []
            recipe_content = soup.find('div', class_='smittenkitchen-recipe') or soup.find('div', class_='entry-content')
            instruction_marker = recipe_content.find(lambda tag: tag.name in ['h3', 'h4', 'h5', 'p'] and 'instructions' in tag.get_text(strip=True).lower())
            current_element = None
            if instruction_marker:
                current_element = instruction_marker.find_next_sibling()
            if current_element:
                if current_element.name == 'ol':
                    instructions_list.extend([li.get_text(strip=True) for li in current_element.find_all('li') if li.get_text(strip=True)])
                else:
                    while current_element:
                        if current_element.name == 'p' and current_element.get_text(strip=True):
                            instructions_list.append(current_element.get_text(strip=True))
                        if current_element.name in ['h1', 'h2', 'h3'] or getattr(current_element, 'attrs', {}).get('id') == 'comments':
                            break
                        current_element = current_element.find_next_sibling()
            data['instructions'] = [i for i in instructions_list if i]
            if not data['instructions']: print(f"SK: Could not reliably find instructions for {url}")
        except Exception as e:
            print(f"SK: Error parsing instructions: {e}"); data['instructions'] = []

        print(f"Custom Smitten Kitchen scrape attempted for {url}")
        return data

    def _scrape_justine_snacks(self, url, soup):
        """Custom scraper for justinesnacks.com"""
        data = {'url': url, 'host': 'justinesnacks.com'}

        # Title
        try:
            title_tag = soup.find('h1', class_='entry-title') or soup.find('h1')
            data['title'] = title_tag.get_text(strip=True) if title_tag else None
        except Exception as e: 
            print(f"JS: Error parsing title: {e}"); data['title'] = None

        # Image (Often featured image)
        try:
            # Look for common WordPress featured image classes or within entry content
            img_tag = soup.select_one('.featured-image img') or soup.select_one('.entry-content img') or soup.find('img')
            data['image'] = img_tag['src'] if img_tag else None
        except Exception as e: 
             print(f"JS: Error parsing image: {e}"); data['image'] = None

        # Yield & Time (Might be missing or need specific selectors)
        data['yields'] = None
        data['total_time'] = None
        # Try finding elements using WPRM classes first if they exist (common plugin)
        try:
            yield_tag = soup.select_one('.wprm-recipe-yield-container .wprm-recipe-yield')
            if yield_tag: data['yields'] = yield_tag.get_text(strip=True)
            
            time_tag = soup.select_one('.wprm-recipe-total-time-container .wprm-recipe-time')
            if time_tag: data['total_time'] = time_tag.get_text(strip=True) # Needs parsing
            
            # Fallback: Look for simple text near top or specific non-plugin classes (less reliable)
            if not data['yields']:
                yield_tag_alt = soup.find(lambda tag: tag.name in ['p','li'] and ('yield' in tag.get_text(strip=True).lower() or 'servings' in tag.get_text(strip=True).lower()))
                if yield_tag_alt: data['yields'] = yield_tag_alt.get_text(strip=True)
            if not data['total_time']:
                 time_tag_alt = soup.find(lambda tag: tag.name in ['p','li'] and 'time' in tag.get_text(strip=True).lower())
                 if time_tag_alt: data['total_time'] = time_tag_alt.get_text(strip=True)
                 
        except Exception as e:
            print(f"JS: Error parsing yield/time: {e}")

        # Ingredients (Refined logic: Find header, then process siblings)
        try:
            ingredients_list = []
            # Find the Ingredients header (h3 usually, case-insensitive)
            ingredient_header = soup.find(['h2', 'h3', 'h4'], string=re.compile(r'Ingredients', re.IGNORECASE))
            
            if ingredient_header:
                current_element = ingredient_header.find_next_sibling()
                while current_element and current_element.name not in ['h1','h2','h3','h4']: # Stop at next header
                    if current_element.name in ['ul', 'ol']:
                        items = current_element.find_all('li')
                        ingredients_list.extend([li.get_text(strip=True) for li in items if li.get_text(strip=True)])
                    elif current_element.name == 'p' and current_element.get_text(strip=True): # Handle ingredients listed in paragraphs
                        ingredients_list.append(current_element.get_text(strip=True))
                    
                    # Move to the next sibling element
                    current_element = current_element.find_next_sibling()
                    # Handle cases where sibling might be NavigableString (whitespace/newlines)
                    while current_element and not hasattr(current_element, 'name'): 
                         current_element = current_element.find_next_sibling()
            
            # Fallback: Check WPRM structure if header method failed
            if not ingredients_list:
                 wprm_container = soup.select_one('.wprm-recipe-ingredients-container')
                 if wprm_container:
                     items = wprm_container.select('.wprm-recipe-ingredient')
                     ingredients_list.extend([item.get_text(strip=True) for item in items if item.get_text(strip=True)])

            data['ingredients'] = [i for i in ingredients_list if i] # Clean empty
            if not data['ingredients']: print(f"JS: Could not reliably find ingredients for {url}")
        except Exception as e: 
            print(f"JS: Error parsing ingredients: {e}"); data['ingredients'] = []

        # Instructions (Refined logic: Find header, then process siblings)
        try:
            instructions_list = []
            instruction_header = soup.find(['h2', 'h3', 'h4'], string=re.compile(r'Instructions|Directions', re.IGNORECASE))
            
            if instruction_header:
                current_element = instruction_header.find_next_sibling()
                while current_element and current_element.name not in ['h1','h2','h3','h4']: # Stop at next header
                    if current_element.name in ['ul', 'ol']:
                        items = current_element.find_all('li')
                        instructions_list.extend([li.get_text(strip=True) for li in items if li.get_text(strip=True)])
                    elif current_element.name == 'p' and current_element.get_text(strip=True):
                        instructions_list.append(current_element.get_text(strip=True))
                        
                    # Move to the next sibling element
                    current_element = current_element.find_next_sibling()
                    # Handle cases where sibling might be NavigableString
                    while current_element and not hasattr(current_element, 'name'): 
                         current_element = current_element.find_next_sibling()
            
            # Fallback: Check WPRM structure if header method failed
            if not instructions_list:
                 wprm_container = soup.select_one('.wprm-recipe-instructions-container')
                 if wprm_container:
                     items = wprm_container.select('.wprm-recipe-instruction-text') # WPRM uses specific class for instruction text
                     instructions_list.extend([item.get_text(strip=True) for item in items if item.get_text(strip=True)])

            data['instructions'] = [i for i in instructions_list if i] # Clean empty
            if not data['instructions']: print(f"JS: Could not reliably find instructions for {url}")
        except Exception as e: 
            print(f"JS: Error parsing instructions: {e}"); data['instructions'] = []

        print(f"Custom Justine Snacks scrape attempted for {url}")
        return data

    def _fetch_and_find_links_paginated(self, start_url, site_name, link_selector_func, next_page_selector_func, max_pages=5):
        """Helper function to fetch links from a starting URL and follow pagination."""
        found_urls = set()
        current_url = start_url
        pages_processed = 0

        while current_url and pages_processed < max_pages:
            print(f"{site_name}: Processing page {pages_processed + 1}: {current_url}")
            soup = self._get_soup(current_url)
            if not soup:
                print(f"{site_name}: Fetch error or empty soup for {current_url}, stopping pagination for this index.")
                break # Stop if we can't fetch a page

            # Find recipe links on the current page
            links_on_page = link_selector_func(soup)
            new_links_count = len(links_on_page - found_urls)
            found_urls.update(links_on_page)
            print(f"{site_name}: Found {new_links_count} new recipe links on this page (Total unique: {len(found_urls)})")

            # Find the next page link
            next_page_url = next_page_selector_func(soup, current_url)
            pages_processed += 1

            if not next_page_url or next_page_url == current_url:
                print(f"{site_name}: No more pages found or next link is same as current. Ending pagination for {start_url}.")
                current_url = None
            else:
                current_url = next_page_url
                # Optional: Add a small delay to be polite to the server
                time.sleep(0.5) 
        
        print(f"{site_name}: Finished processing index {start_url}. Found {len(found_urls)} total unique links after {pages_processed} pages.")
        return found_urls

    def get_recipe_links_from_smitten_kitchen(self, index_urls, max_pages_per_index=5):
        print(f"--- Starting Smitten Kitchen Link Discovery for {len(index_urls)} index URL(s) ---")
        all_found_urls = set()
        processed_indices = 0

        def find_sk_links(soup):
            links = set()
            # Find links within common article containers or main content area
            content_area = soup.find('main') or soup.find('div', id='content') or soup
            all_a_tags = content_area.find_all('a', href=True)
            for link in all_a_tags:
                href = link['href']
                # Regex to match typical SK post URLs (YYYY/MM/slug)
                if href.startswith("https://smittenkitchen.com/") and re.search(r'/\d{4}/\d{2}/[^/]+/?$', href): 
                    if "/category/" not in href and "/tag/" not in href:
                        links.add(href)
            return links

        def find_sk_next_page(soup, base_url):
            # Look for standard WordPress pagination links
            next_link = soup.select_one('a.nextpostslink') or soup.find('a', string=re.compile(r'Older posts', re.I))
            if next_link and next_link['href']:
                # Ensure the link is absolute
                return urljoin(base_url, next_link['href']) 
            return None

        for url in index_urls:
            print(f"Processing Smitten Kitchen index root: {url}")
            found_for_index = self._fetch_and_find_links_paginated(
                url, "SK", find_sk_links, find_sk_next_page, max_pages=max_pages_per_index
            )
            all_found_urls.update(found_for_index)
            processed_indices += 1

        print(f"--- Smitten Kitchen Complete: {len(all_found_urls)} unique URLs found from {processed_indices} index source(s) ---\n")
        return list(all_found_urls)

    def get_recipe_links_from_justine_snacks(self, index_urls, max_pages_per_index=5):
        print(f"--- Starting Justine Snacks Link Discovery for {len(index_urls)} index URL(s) ---")
        all_found_urls = set()
        processed_indices = 0

        def find_js_links(soup):
            links = set()
            # Look for links within the main content area or specific article containers
            content_area = soup.find('main', id='main') or soup.find('div', class_='site-content') or soup
            all_a_tags = content_area.find_all('a', href=True)
            for link in all_a_tags:
                href = link['href']
                # Check if it looks like a recipe post URL (avoids category/tag/page links)
                if href.startswith("https://justinesnacks.com/") and "/category/" not in href and "/tag/" not in href and "/page/" not in href and "#" not in href and len(href) > len("https://justinesnacks.com/"):
                     # Simple check: URL path has more than one segment usually indicates a post
                     path_parts = urlparse(href).path.strip('/').split('/')
                     if len(path_parts) >= 1: # e.g., /recipe-name/
                        links.add(href)
            return links

        def find_js_next_page(soup, base_url):
            # Look for standard WordPress pagination links
            next_link = soup.select_one('a.next.page-numbers') or soup.find('a', string=re.compile(r'Next', re.I))
            # Sometimes it might be an older posts link too
            if not next_link:
                 next_link = soup.find('a', string=re.compile(r'Older Posts', re.I))
                 
            if next_link and next_link['href']:
                 # Ensure the link is absolute
                return urljoin(base_url, next_link['href'])
            return None

        for url in index_urls:
            print(f"Processing Justine Snacks index root: {url}")
            found_for_index = self._fetch_and_find_links_paginated(
                url, "JS", find_js_links, find_js_next_page, max_pages=max_pages_per_index
            )
            all_found_urls.update(found_for_index)
            processed_indices += 1

        print(f"--- Justine Snacks Complete: {len(all_found_urls)} unique URLs found from {processed_indices} index source(s) ---\n")
        return list(all_found_urls)
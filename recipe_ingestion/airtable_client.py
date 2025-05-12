from airtable import Airtable

class AirtableClient:
    def __init__(self, api_key, base_id, table_name):
        if not api_key or not base_id or not table_name:
            raise ValueError("Airtable API Key, Base ID, or Table Name was not provided during initialization.")
        
        self.airtable = Airtable(base_id, table_name, api_key)

    def get_all_records(self, view=None, max_records=0, fields=None, sort=None, formula=None):
        """
        Retrieves all records from the table.
        Args:
            view (str, optional): The name or ID of the view.
            max_records (int, optional): The maximum number of records to retrieve.
            fields (list, optional): A list of field names to retrieve.
            sort (list, optional): A list of tuples for sorting, e.g., [('FieldName', 'asc')].
            formula (str, optional): A formula used to filter records.
        Returns:
            list: A list of records.
        """
        try:
            params = {}
            if view:
                params['view'] = view
            if max_records > 0:
                params['max_records'] = max_records
            if fields:
                params['fields'] = fields
            if sort:
                params['sort'] = sort
            if formula:
                params['filterByFormula'] = formula
            
            return self.airtable.get_all(**params)
        except Exception as e:
            print(f"Error getting records from Airtable: {e}")
            return []

    def add_record(self, data):
        """
        Adds a new record to the table.
        Args:
            data (dict): The data for the new record.
        Returns:
            dict: The created record, or None if an error occurred.
        """
        try:
            return self.airtable.insert(data)
        except Exception as e:
            print(f"Error adding record to Airtable: {e}")
            # You might want to implement more sophisticated error handling or logging here
            return None

    def update_record(self, record_id, data):
        """
        Updates an existing record in the table.
        Args:
            record_id (str): The ID of the record to update.
            data (dict): The data to update.
        Returns:
            dict: The updated record, or None if an error occurred.
        """
        try:
            return self.airtable.update(record_id, data)
        except Exception as e:
            print(f"Error updating record in Airtable: {e}")
            return None

    def delete_record(self, record_id):
        """
        Deletes a record from the table.
        Args:
            record_id (str): The ID of the record to delete.
        Returns:
            dict: The deletion confirmation, or None if an error occurred.
        """
        try:
            return self.airtable.delete(record_id)
        except Exception as e:
            print(f"Error deleting record from Airtable: {e}")
            return None

# Example Usage (optional - for testing this client directly)
# if __name__ == '__main__':
#     client = AirtableClient('your_api_key', 'your_base_id', 'your_table_name')
    
    # Test getting records
    # print("Fetching records...")
    # records = client.get_all_records(max_records=5, fields=["Title", "Source URL"])
    # if records:
    #     for record in records:
    #         print(f"ID: {record['id']}, Title: {record.get('fields', {}).get('Title')}")
    # else:
    #     print("No records found or error occurred.")

    # Test adding a record (BE CAREFUL - THIS WILL ADD DATA)
    # print("\nAdding a test record...")
    # new_recipe_data = {
    #     "Title": "Test Recipe from Script",
    #     "Source URL": "http://example.com/test",
    #     "Course": "Dessert",
    #     "Approved": False 
    # }
    # created_record = client.add_record(new_recipe_data)
    # if created_record:
    #     print(f"Created record: {created_record}")
    #     # Test updating the record
    #     # record_id_to_update = created_record['id']
    #     # print(f"\nUpdating record {record_id_to_update}...")
    #     # updated_data = {"Notes": "This is an updated note."}
    #     # updated_record = client.update_record(record_id_to_update, updated_data)
    #     # if updated_record:
    #     #     print(f"Updated record: {updated_record}")

        # Test deleting the record (BE CAREFUL - THIS WILL DELETE DATA)
        # record_id_to_delete = created_record['id']
        # print(f"\nDeleting record {record_id_to_delete}...")
        # deletion_info = client.delete_record(record_id_to_delete)
        # if deletion_info and deletion_info.get('deleted'):
        #     print(f"Record {record_id_to_delete} deleted successfully.")
        # else:
        #     print(f"Failed to delete record {record_id_to_delete}.")
    # else:
    #     print("Failed to create a test record.")

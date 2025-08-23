# CSV Import Workflow
## User Journey

The user journey for importing CSV files is as follows:

1. **Initiate Import:** The user initiates the import process from the application's main dashboard or a dedicated "Import" section.
2. **File Selection:** The user is prompted to select a CSV file from their local system.
3. **Field Mapping:** The application automatically maps the columns in the CSV file to the corresponding fields in the database. The user can review and adjust these mappings if necessary.
4. **Data Validation:** The application validates the data in the CSV file to ensure it meets the required format and constraints.
5. **Import Confirmation:** The user is presented with a summary of the data to be imported and asked to confirm the import.
6. **Import Processing:** The application processes the CSV file and imports the data into the database.
7. **Import Completion:** The user is notified of the import's success or failure. If the import fails, the user is provided with a list of errors that occurred during the process.
## Supported CSV Formats

The application supports the following CSV formats:

*   **Comma-separated:** This is the most common CSV format, where values are separated by commas.
*   **Tab-separated:** In this format, values are separated by tabs.
*   **Semicolon-separated:** This format uses semicolons to separate values.

## Field Mappings

The application will attempt to automatically map the columns in the CSV file to the following fields:

*   `Title`
*   `Author`
*   `ISBN`
*   `Publisher`
*   `Publication Date`
*   `Number of Pages`
*   `Genre`

## UI Flow

1.  **"Import CSV" Button:** The user clicks the "Import CSV" button on the main dashboard.
2.  **File Selection Modal:** A modal window appears, prompting the user to select a CSV file.
3.  **Field Mapping Screen:** After a file is selected, the user is taken to a screen where they can map the CSV columns to the application's fields.
4.  **Data Preview:** A preview of the data to be imported is displayed, based on the current field mappings.
5.  **"Import" Button:** The user clicks the "Import" button to begin the import process.
6.  **Progress Bar:** A progress bar is displayed, showing the status of the import.
## Error Handling and Validation

The application will perform the following validation checks during the import process:

*   **Required Fields:** The `Title` and `Author` fields are required. If either of these fields is missing from a row, the row will be skipped and an error will be logged.
*   **Data Types:** The `Publication Date` field must be in a valid date format (e.g., YYYY-MM-DD), and the `Number of Pages` field must be a positive integer.
*   **Duplicate Records:** The application will check for duplicate records based on the `ISBN` field. If a book with the same ISBN already exists in the database, the row will be skipped and an error will be logged.

The following are some examples of error messages that may be displayed to the user:

*   "Row 5: Missing required field: Title"
*   "Row 12: Invalid date format for Publication Date. Please use YYYY-MM-DD."
## Example CSV Files

**Comma-separated:**

```csv
Title,Author,ISBN,Publisher,Publication Date,Number of Pages,Genre
The Lord of the Rings,J.R.R. Tolkien,978-0618640157,Houghton Mifflin Harcourt,2005-09-15,1216,Fantasy
The Hitchhiker's Guide to the Galaxy,Douglas Adams,978-0345391803,Del Rey,1995-09-27,224,Science Fiction
```

**Tab-separated:**

```
Title	Author	ISBN	Publisher	Publication Date	Number of Pages	Genre
The Lord of the Rings	J.R.R. Tolkien	978-0618640157	Houghton Mifflin Harcourt	2005-09-15	1216	Fantasy
The Hitchhiker's Guide to the Galaxy	Douglas Adams	978-0345391803	Del Rey	1995-09-27	224	Science Fiction
```



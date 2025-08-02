# Final Step: Grant Access to Your Google Sheet

## Service Account Email:
`serviceaccount@stockscan-465621.iam.gserviceaccount.com`

## Steps:

1. **Open your Google Sheet**:
   https://docs.google.com/spreadsheets/d/1H3EOvKRu4YUl2BldU6dNR0YdaDUIMC0Oa4xkuqInET0/edit

2. **Click the "Share" button** (top right)

3. **Add the service account email**:
   - Paste: `serviceaccount@stockscan-465621.iam.gserviceaccount.com`
   - Select permission: **Editor** (for read/write access)
   - Uncheck "Notify people"
   - Click "Share"

4. **That's it!** Your app can now read and write to the Google Sheet.

## App Configuration:
- ✅ Service account JSON is already in your project
- ✅ Google Sheets API client is configured
- ✅ Your Sheet ID is already set up
- ⏳ Just need to share the sheet with the service account

Once you share the sheet, the app will be able to:
- Read your period history from Google Sheets
- Write new periods to Google Sheets
- Sync data between devices
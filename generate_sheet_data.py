import uuid
from datetime import datetime, timedelta

# Your period data
periods = [
    ("2025-01-14", 7),
    ("2025-02-15", 7),
    ("2025-03-16", 7),
    ("2025-04-15", 7),
    ("2025-05-10", 7),
    ("2025-06-09", 7),
    ("2025-07-09", 7),
]

print("Copy and paste this data into your Google Sheet starting from row 2:")
print("\nID\tStartDate\tEndDate\tDuration\tNotes")

for start_date_str, duration in periods:
    # Generate UUID
    period_id = str(uuid.uuid4())
    
    # Parse start date
    start_date = datetime.strptime(start_date_str, "%Y-%m-%d")
    
    # Calculate end date
    end_date = start_date + timedelta(days=duration - 1)
    
    # Format dates in ISO8601
    start_iso = start_date.strftime("%Y-%m-%dT%H:%M:%SZ")
    end_iso = end_date.strftime("%Y-%m-%dT%H:%M:%SZ")
    
    # Print tab-separated values for easy copy-paste
    print(f"{period_id}\t{start_iso}\t{end_iso}\t{duration}\t")

print("\n✅ Copy the data above and paste it into your Google Sheet!")
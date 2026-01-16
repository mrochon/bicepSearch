import json
import os

# Read the JSONL file
input_file = r'c:\temp\bicepSearch\indexDef\indexDefinitions\shoes\shoes.jsonl'
output_dir = r'c:\temp\bicepSearch\indexDef\indexDefinitions\shoes\shoes-clr'

# Create output directory if it doesn't exist
os.makedirs(output_dir, exist_ok=True)

# Process each line and create individual files
count = 0
with open(input_file, 'r') as f:
    for line in f:
        data = json.loads(line.strip())
        
        # Get the id for the filename
        file_id = data['id']
        output_file = os.path.join(output_dir, f'{file_id}.json')
        
        # Write the object to its own file
        with open(output_file, 'w') as out_f:
            json.dump(data, out_f, indent=2)
        
        count += 1

print(f'Successfully split {count} objects into individual files in {output_dir}')

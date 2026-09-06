import os
import re

# Comprehensive regex to catch all Unicode emojis and symbols
EMOJI_PATTERN = re.compile(
 "["
 "\U0001F1E0-\U0001F1FF" # flags (iOS)
 "\U0001F300-\U0001F5FF" # symbols & pictographs
 "\U0001F600-\U0001F64F" # emoticons
 "\U0001F680-\U0001F6FF" # transport & map symbols
 "\U0001F700-\U0001F77F" # alchemical symbols
 "\U0001F780-\U0001F7FF" # Geometric Shapes Extended
 "\U0001F800-\U0001F8FF" # Supplemental Arrows-C
 "\U0001F900-\U0001F9FF" # Supplemental Symbols and Pictographs
 "\U0001FA00-\U0001FA6F" # Chess Symbols
 "\U0001FA70-\U0001FAFF" # Symbols and Pictographs Extended-A
 "\U00002702-\U000027B0" # Dingbats
 "\U000024C2-\U0001F251"
 "\U0001F004-\U0001F0CF"
 "\U0001F900-\U0001F9FF"
 "\U0001F000-\U0001F02F"
 "\U0001F0A0-\U0001F0FF"
 ""
 "]+",
 flags=re.UNICODE
)

def clean_file(filepath):
 try:
 with open(filepath, 'r', encoding='utf-8') as f:
 content = f.read()
 
 new_content = EMOJI_PATTERN.sub('', content)
 # Clean up any leftover double spaces
 new_content = re.sub(r' +', ' ', new_content)
 new_content = re.sub(r'# +', '# ', new_content)
 new_content = re.sub(r'## +', '## ', new_content)
 new_content = re.sub(r'### +', '### ', new_content)
 
 if content != new_content:
 with open(filepath, 'w', encoding='utf-8') as f:
 f.write(new_content)
 print(f"Cleaned emojis from: {filepath}")
 except Exception as e:
 print(f"Error processing {filepath}: {e}")

def walk_and_clean():
 workspace = r"c:\Users\pc\Documents\HiLyst\Shopify E-Commerce Sales Dataset"
 for root, dirs, files in os.walk(workspace):
 # skip .git or system folders if any
 for f in files:
 if f.endswith(('.md', '.html', '.js', '.css', '.py', '.sql', '.json')):
 clean_file(os.path.join(root, f))

if __name__ == "__main__":
 walk_and_clean()

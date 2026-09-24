import subprocess
import os

try:
    subprocess.run(["git", "push", "origin", "HEAD:refs/heads/jules-2446160907964472673-257b5518", "--force"], check=True)
except Exception as e:
    print(f"Error: {e}")

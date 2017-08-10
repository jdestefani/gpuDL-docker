from notebook.auth import passwd
import fileinput
import os

# Genrate password from notebook library
sha1Pass = passwd()

# Insert it in the configuration file
with fileinput.FileInput(os.path.expanduser("~/.jupyter/jupyter_notebook_config.py"), inplace=True, backup='.bak') as file:
        for line in file:
                print(line.replace("#c.NotebookApp.password = \'\'", "c.NotebookApp.password = u\'"+sha1Pass+"\'"), end='')





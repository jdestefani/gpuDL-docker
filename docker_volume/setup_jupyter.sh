#!/bin/bash

jupyter notebook --allow-root --generate-config
python config_password.py
#jupyter notebook --allow-root --no-browser --ip=0.0.0.0

#!/bin/bash

docker run -p 8888:8888 \
           --name MUDS_day1_linux \
           -v /mnt/data/MUDS/EST/Practice:/home/jovyan/work \
           jupyter/datascience-notebook \
           start-notebook.sh --NotebookApp.token='muds'

#!/bin/sh

docker service create --name migration eguefif/teacher_coop:20260919130041 /app/bin/migrate

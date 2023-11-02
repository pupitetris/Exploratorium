#!/bin/bash

DBFILE=$1

./dump_ddl.sh $DBFILE > ddl.sql
./dump_data.sh $DBFILE > data.sql

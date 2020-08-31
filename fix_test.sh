#!/bin/bash

count=1

function add_one() {
  ((count=count+1))
  echo "Count: $count"
}

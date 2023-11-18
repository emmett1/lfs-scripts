#!/bin/sh

for i in core extra multilib contrib; do
	httpup-repgen $i
done

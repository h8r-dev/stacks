#!/usr/bin/env bash

gh secret --repo ${ORGANIZATION}/${NAME} set ${KEY} --body "${VALUE}"

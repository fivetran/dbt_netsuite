#!/bin/bash

set -euo pipefail

apt-get update
apt-get install libsasl2-dev

python3 -m venv venv
. venv/bin/activate
pip install --upgrade pip setuptools
pip install -r integration_tests/requirements.txt

mkdir -p ~/.dbt
cp integration_tests/ci/sample.profiles.yml ~/.dbt/profiles.yml

db=$1
echo `pwd`
cd integration_tests
dbt deps

if [ "$db" = "databricks-sql" ]; then
dbt seed --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db" --full-refresh
dbt source freshness --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db" || echo "...Only verifying freshness runs…"
dbt compile --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db"
dbt run --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db" --full-refresh
dbt run --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db"
dbt test --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db"
dbt run --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2, netsuite2__using_to_subsidiary: true, netsuite2__multibook_accounting_enabled: true, netsuite2__using_exchange_rate: false, netsuite2__using_vendor_categories: false, netsuite2__using_jobs: false, netsuite2__using_employees: false, netsuite2__fiscal_calendar_enabled: true}' --target "$db" --full-refresh
dbt run --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2, netsuite2__using_to_subsidiary: true, netsuite2__multibook_accounting_enabled: true, netsuite2__using_exchange_rate: false, netsuite2__using_vendor_categories: false, netsuite2__using_jobs: false, netsuite2__using_employees: false, netsuite2__fiscal_calendar_enabled: true}' --target "$db"
dbt test --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db"
dbt run --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2, netsuite2__using_to_subsidiary: true, netsuite2__using_exchange_rate: true}' --target "$db" --full-refresh
dbt run --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2, netsuite2__using_to_subsidiary: true, netsuite2__using_exchange_rate: true}' --target "$db"
dbt test --vars '{netsuite_schema: netsuite_integrations_tests_sqlw_2}' --target "$db"

else

dbt seed --target "$db" --full-refresh
dbt source freshness --target "$db" || echo "...Only verifying freshness runs…"
dbt compile --target "$db"
dbt run --target "$db" --full-refresh
dbt run --target "$db"
dbt test --target "$db"
dbt run --vars '{netsuite2__using_to_subsidiary: true, netsuite2__multibook_accounting_enabled: true, netsuite2__using_exchange_rate: false, netsuite2__using_vendor_categories: false, netsuite2__using_jobs: false, netsuite2__using_employees: false, netsuite2__fiscal_calendar_enabled: true}' --target "$db" --full-refresh
dbt run --vars '{netsuite2__using_to_subsidiary: true, netsuite2__multibook_accounting_enabled: true, netsuite2__using_exchange_rate: false, netsuite2__using_vendor_categories: false, netsuite2__using_jobs: false, netsuite2__using_employees: false, netsuite2__fiscal_calendar_enabled: true}' --target "$db"
dbt test --target "$db"
dbt run --vars '{netsuite2__using_to_subsidiary: true, netsuite2__using_exchange_rate: true}' --target "$db" --full-refresh
dbt run --vars '{netsuite2__using_to_subsidiary: true, netsuite2__using_exchange_rate: true}' --target "$db"
dbt test --target "$db"
fi

dbt run-operation fivetran_utils.drop_schemas_automation --target "$db"

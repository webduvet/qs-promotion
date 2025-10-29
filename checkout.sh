#!/usr/bin/env bash
set -euo pipefail

ACCOUNT_ID="${ACCOUNT_ID:-550094171826}"
REGION="${REGION:-eu-west-1}"
ENV="${ENV:-dev}"                   # dev|stg|prod
OUT="dev/$ENV"
mkdir -p "$OUT"/{data-sources,datasets,analyses,dashboards,themes,templates}

# Helper: paginate list calls
list_all() { # $1=resource_type
  local next="" page
  while :; do
    case "$1" in
      data-sources) page=$(aws quicksight list-data-sources --aws-account-id "$ACCOUNT_ID" --region "$REGION" ${next:+--next-token "$next"}) ;;
      datasets)     page=$(aws quicksight list-data-sets     --aws-account-id "$ACCOUNT_ID" --region "$REGION" ${next:+--next-token "$next"}) ;;
      analyses)     page=$(aws quicksight list-analyses      --aws-account-id "$ACCOUNT_ID" --region "$REGION" ${next:+--next-token "$next"}) ;;
      dashboards)   page=$(aws quicksight list-dashboards    --aws-account-id "$ACCOUNT_ID" --region "$REGION" ${next:+--next-token "$next"}) ;;
      themes)       page=$(aws quicksight list-themes        --aws-account-id "$ACCOUNT_ID" --region "$REGION" ${next:+--next-token "$next"}) ;;
      templates)    page=$(aws quicksight list-templates     --aws-account-id "$ACCOUNT_ID" --region "$REGION" ${next:+--next-token "$next"}) ;;
    esac
    jq -r '
      .NextToken as $n
      | ( .DataSources[]?.DataSourceId,
          .DataSetSummaries[]?.DataSetId,
          .AnalysisSummaryList[]?.AnalysisId,
          .DashboardSummaryList[]?.DashboardId,
          .ThemeSummaryList[]?.ThemeId,
          .TemplateSummaryList[]?.TemplateId ) | select(.!=null)
      | @sh
    ' <<<"$page"
    next=$(jq -r '.NextToken // empty' <<<"$page")
    [[ -z "$next" ]] && break
  done
}

echo "==> Exporting Data Sources"
while read -r id; do
  id=${id//\'/}  # unquote
  aws quicksight describe-data-source \
    --aws-account-id "$ACCOUNT_ID" --data-source-id "$id" \
    --region "$REGION" --output json > "$OUT/data-sources/$id.json"
done < <(list_all data-sources)

echo "==> Exporting Data Sets"
while read -r id; do
  id=${id//\'/}
  aws quicksight describe-data-set \
    --aws-account-id "$ACCOUNT_ID" --data-set-id "$id" \
    --region "$REGION" --output json > "$OUT/datasets/$id.json"
done < <(list_all datasets)

echo "==> Exporting Analyses (definitions)"
while read -r id; do
  id=${id//\'/}
  aws quicksight describe-analysis-definition \
    --aws-account-id "$ACCOUNT_ID" --analysis-id "$id" \
    --region "$REGION" --output json > "$OUT/analyses/$id.definition.json"
done < <(list_all analyses)

echo "==> Exporting Dashboards (definitions)"
while read -r id; do
  id=${id//\'/}
  aws quicksight describe-dashboard-definition \
    --aws-account-id "$ACCOUNT_ID" --dashboard-id "$id" \
    --region "$REGION" --output json > "$OUT/dashboards/$id.definition.json"
done < <(list_all dashboards)

echo "==> Exporting Themes"
while read -r id; do
  id=${id//\'/}
  aws quicksight describe-theme \
    --aws-account-id "$ACCOUNT_ID" --theme-id "$id" \
    --region "$REGION" --output json > "$OUT/themes/$id.json"
done < <(list_all themes)

echo "==> Exporting Templates"
while read -r id; do
  id=${id//\'/}
  aws quicksight describe-template \
    --aws-account-id "$ACCOUNT_ID" --template-id "$id" \
    --region "$REGION" --output json > "$OUT/templates/$id.json"
done < <(list_all templates)

echo "✅ Export complete: $OUT"

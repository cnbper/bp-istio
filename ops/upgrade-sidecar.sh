# upgrade-sidecar.sh，通过修改终止宽限期来触发滚动更新
NS=$1

function refresh-all-pods() {
    echo
    DEPLOYMENT_LIST=$(kubectl -n $NS get deployment -o jsonpath='{.items[*].metadata.name}')
    echo "Refreshing pods in all Deployments"
    for deployment_name in $DEPLOYMENT_LIST ; do
        TERMINATION_GRACE_PERIOD_SECONDS=$(kubectl -n $NS get deployment "$deployment_name" -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}')
    if [ "$TERMINATION_GRACE_PERIOD_SECONDS" -eq 30 ]; then
        TERMINATION_GRACE_PERIOD_SECONDS='31'
    else
        TERMINATION_GRACE_PERIOD_SECONDS='30'
    fi
    patch_string="{\"spec\":{\"template\":{\"spec\":{\"terminationGracePeriodSeconds\":$TERMINATION_GRACE_PERIOD_SECONDS}}}}"
    kubectl -n $NS patch deployment $deployment_name -p $patch_string
done
echo
}

refresh-all-pods $NAMESPACE
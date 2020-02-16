while true

do
#    sleep 1
#    kubectl -n samples exec $(kubectl -n samples get pod -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep -- curl -sL -o /dev/null -D - http://httpbin.samples:8000/ip
    curl -sL -o /dev/null -D - http://httpbin.sloth.com/ip
done
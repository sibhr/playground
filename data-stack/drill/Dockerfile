# Drill dockerfile PR https://github.com/apache/drill/pull/1348/commits

FROM drill/apache-drill-centos:1.14.0-SNAPSHOT

ENTRYPOINT []

#CMD /bin/bash

CMD  export DRILL_EMBEDDED=1 && /opt/drill/bin/drillbit.sh start && tail -f /opt/drill/
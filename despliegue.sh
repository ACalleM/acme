# https://www.katacoda.com/courses/openshift/playgrounds/openshift46
git clone https://github.com/ACalleM/acme
cd acme
oc new-project acoc-desa-bck
oc new-project tlc1-desa-bck

oc create -f template-configmap-tapv4-config-v1.yml -n acoc-desa-bck
oc create -f template-pvc-telco-nas-v1.yml -n acoc-desa-bck
oc create -f template-srv-nuc-jee-v4.yml -n acoc-desa-bck
oc create -f template-srv-nuc-jee-nas-v4.yml -n acoc-desa-bck

oc process template-configmap-tapv4-config-v1 -n acoc-desa-bck|oc create -n tlc1-desa-bck -f –
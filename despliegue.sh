# https://www.katacoda.com/courses/openshift/playgrounds/openshift46
# git clone https://github.com/ACalleM/acme
NAMESPACE_ACOC="acoc-desa-bck"
NAMESPACE_DESTINO="tlc1-desa-bck"
NAMESPACE_COMPILACION="imgb-desa-bck"
TEMPLATE="template-srv-nuc-jee-v4"

APLICACION="coco-srv-nuc-jee-bank-4"
VERSION_MAJOR="4"
VERSION="4.0.0"
FICHERO="./rest-service-0.0.1-SNAPSHOT.jar"
IMAGEN_BASE="openshift/openjdk18-openshift:1.5"

#CREACION ENTORNO
echo CREACION ENTORNO
oc new-project ${NAMESPACE_ACOC}
oc new-project ${NAMESPACE_DESTINO}
oc new-project ${NAMESPACE_COMPILACION}

oc create -f template-configmap-tapv4-config-v1.yml -n ${NAMESPACE_ACOC}
oc create -f template-pvc-telco-nas-v1.yml -n ${NAMESPACE_ACOC}
oc create -f template-srv-nuc-jee-v4.yml -n ${NAMESPACE_ACOC}
oc create -f template-srv-nuc-jee-nas-v4.yml -n ${NAMESPACE_ACOC}
oc process template-configmap-tapv4-config-v1 -n ${NAMESPACE_ACOC}|oc create -n ${NAMESPACE_DESTINO} -f -

#JENKINS
echo JENKINS

oc get istag ${APLICACION}:${VERSION} -n ${NAMESPACE_DESTINO}
oc get bc ${APLICACION} -n ${NAMESPACE_DESTINO}

oc new-build --name ${APLICACION} --binary=true --strategy=source --image-stream ${IMAGEN_BASE} --to ${APLICACION}:${VERSION_MAJOR} -n ${NAMESPACE_COMPILACION}
oc start-build ${APLICACION} --from-file=${FICHERO} -n ${NAMESPACE_COMPILACION} --wait=true
oc tag ${APLICACION}:${VERSION_MAJOR} ${APLICACION}:${VERSION} -n ${NAMESPACE_COMPILACION}

oc logs bc/${APLICACION} -n ${NAMESPACE_COMPILACION}
oc describe bc/${APLICACION} -n ${NAMESPACE_COMPILACION}

#CLARIVE
echo CLARIVE
oc tag ${NAMESPACE_COMPILACION}/${APLICACION}:${VERSION} ${NAMESPACE_DESTINO}/${APLICACION}:${VERSION} ${NAMESPACE_DESTINO}/${APLICACION}:${VERSION_MAJOR}
oc get dc ${APLICACION} -n ${NAMESPACE_DESTINO}
oc new-app -e <var-entorno>=<valor> … -p <var-plantilla>=<valor> … -n <namespace> --template=<namespace_ACOC_segun_entorno>/<nombre-template>
oc new-app -e TZ=Europe/Madrid -p APPLICATION_NAME=${APLICACION} -p VERSION_TAG=${VERSION} -p NAMESPACE=${NAMESPACE_DESTINO} -p DOMAIN_SUFFIX=.acme -n ${NAMESPACE_DESTINO} --template ${NAMESPACE_ACOC}/${TEMPLATE}
oc rollout latest ${APLICACION} -n ${NAMESPACE_DESTINO}

#CLARIVE PATCH
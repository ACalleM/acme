# https://www.katacoda.com/courses/openshift/playgrounds/openshift46
# git clone https://github.com/ACalleM/acme
# Cambios:
# api version 1 en templates
# imagen base openshift/redhat-openjdk18-openshift:1.5
# new-app con --as-deployment-config

inicio_tarea()
{
	read -rsp $'PULSA UNA TECLA PARA CONTINUAR...\n' -n1 key
	clear
	echo $
}

NAMESPACE_ACOC="acoc-desa-bck"
NAMESPACE_DESTINO="tlc1-desa-bck"
NAMESPACE_COMPILACION="imgb-desa-bck"
TEMPLATE="template-srv-nuc-jee-v4"

APLICACION="coco-srv-nuc-jee-bank-4"
VERSION_MAJOR="4"
VERSION="4.0.0"
FICHERO="./rest-service-0.0.1-SNAPSHOT.jar"
IMAGEN_BASE="openshift/redhat-openjdk18-openshift:1.5"

#CREACION ENTORNO
inicio_tarea CREACION NAMESPACES
oc new-project ${NAMESPACE_ACOC}
oc new-project ${NAMESPACE_DESTINO}
oc new-project ${NAMESPACE_COMPILACION}

inicio_tarea CREACION TEMPLATES
oc create -f template-configmap-tapv4-config-v1.yml -n ${NAMESPACE_ACOC}
oc create -f template-pvc-telco-nas-v1.yml -n ${NAMESPACE_ACOC}
oc create -f template-srv-nuc-jee-v4.yml -n ${NAMESPACE_ACOC}
oc create -f template-srv-nuc-jee-nas-v4.yml -n ${NAMESPACE_ACOC}

inicio_tarea INICIALIZACION NAMESPACES
oc process template-configmap-tapv4-config-v1 -n ${NAMESPACE_ACOC}|oc create -n ${NAMESPACE_DESTINO} -f -

#JENKINS
inicio_tarea COMPROBACION BUILD
oc get istag ${APLICACION}:${VERSION} -n ${NAMESPACE_DESTINO}
oc get bc ${APLICACION} -n ${NAMESPACE_DESTINO}

inicio_tarea CREACION BUILD
oc new-build --name ${APLICACION} --binary=true --strategy=source --image-stream=${IMAGEN_BASE} --to ${APLICACION}:${VERSION_MAJOR} -n ${NAMESPACE_COMPILACION}

inicio_tarea EJECUCION BUILD
oc start-build ${APLICACION} --from-file=${FICHERO} -n ${NAMESPACE_COMPILACION} --wait=true

inicio_tarea OBTENCION DETALLES BUILD
oc logs bc/${APLICACION} -n ${NAMESPACE_COMPILACION}
oc describe bc/${APLICACION} -n ${NAMESPACE_COMPILACION}

inicio_tarea TAGEO IMAGEN
oc tag ${APLICACION}:${VERSION_MAJOR} ${APLICACION}:${VERSION} -n ${NAMESPACE_COMPILACION}

#CLARIVE
inicio_tarea TAGEO IMAGEN ENTRE ENTORNOS
oc tag ${NAMESPACE_COMPILACION}/${APLICACION}:${VERSION} ${NAMESPACE_DESTINO}/${APLICACION}:${VERSION} ${NAMESPACE_DESTINO}/${APLICACION}:${VERSION_MAJOR}

inicio_tarea COMPROBACION DEPLOYMENT
oc get dc ${APLICACION} -n ${NAMESPACE_DESTINO}

inicio_tarea CREACION DEPLOYMENT
oc new-app --as-deployment-config -e TZ=Europe/Madrid -p APPLICATION_NAME=${APLICACION} -p VERSION_TAG=${VERSION} -p NAMESPACE=${NAMESPACE_DESTINO} -p DOMAIN_SUFFIX=.acme -n ${NAMESPACE_DESTINO} --template ${NAMESPACE_ACOC}/${TEMPLATE}

inicio_tarea EJECUCION DEPLOYMENT
oc rollout latest ${APLICACION} -n ${NAMESPACE_DESTINO}

inicio_tarea OBTENCION DETALLE DESPLIEGUE
oc rollout status dc/${APLICACION} -n ${NAMESPACE_DESTINO}

#CLARIVE PATCH
inicio_tarea MODIFICACION DEPLOYMENT
oc patch dc/${APLICACION} --patch "$(oc process ${TEMPLATE} -p APPLICATION_NAME=${APLICACION} -p VERSION_TAG=${VERSION} -p NAMESPACE=${NAMESPACE_DESTINO} -p DOMAIN_SUFFIX=.acme -p NUM_REPLICAS=2 -n ${NAMESPACE_ACOC} -o json | jq -c ‘.items[] | select(.kind=="DeploymentConfig") | del(.spec.template.spec.containers[].image)’)" -n ${NAMESPACE_DESTINO}

inicio_tarea MODIFICACION VARIABLES
oc set env dc/${APLICACION} --overwrite -e TZ=Europe/Madrid -e ACME=77 -n ${NAMESPACE_DESTINO}

inicio_tarea REDESPLIEGUE
oc rollout latest ${APLICACION} -n ${NAMESPACE_DESTINO}

inicio_tarea ROLLBACK
oc rollback ${APLICACION} -n ${NAMESPACE_DESTINO}

inicio_tarea FIN
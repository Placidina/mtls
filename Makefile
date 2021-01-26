EASYRSA_DIRECTORY=easyrsa

all: create

test:
	curl -k --http2 -vvv --cacert certs/ca.crt --key certs/client.key --cert certs/client.crt https://placidina.int/

easysa-init:
ifeq "$(wildcard $(EASYRSA_DIRECTORY) )" ""
	@curl -fSsLO https://storage.googleapis.com/kubernetes-release/easy-rsa/easy-rsa.tar.gz
	@tar xzf easy-rsa.tar.gz
	@rm easy-rsa.tar.gz
	@mv easy-rsa-master/ easyrsa/
endif

	@cd easyrsa/easyrsa3 && rm -rf pki
	@cd easyrsa/easyrsa3 && ./easyrsa init-pki

easysa-authority:
	@cd easyrsa/easyrsa3 && ./easyrsa --batch "--req-cn=Placidina Fake Certificate Authority" build-ca nopass
	@cp easyrsa/easyrsa3/pki/ca.crt certs/ca.crt

easysa-server:
	@cd easyrsa/easyrsa3 && ./easyrsa --batch "--req-cn=placidina.int" --subject-alt-name="DNS:placidina.int,email:contact@placidina.int" --days=365 build-server-full server nopass
	@cp easyrsa/easyrsa3/pki/issued/server.crt certs/server.crt
	@cp easyrsa/easyrsa3/pki/private/server.key certs/server.key

easysa-client:
	@cd easyrsa/easyrsa3 && ./easyrsa --batch "--req-cn=Placidina" --subject-alt-name="email:placidina@placidina.int" --days=365 build-client-full client nopass
	@cp easyrsa/easyrsa3/pki/issued/client.crt certs/client.crt
	@cp easyrsa/easyrsa3/pki/private/client.key certs/client.key

easysa: easysa-init easysa-authority easysa-server easysa-client
	@openssl verify -CAfile certs/ca.crt certs/server.crt
	@openssl verify -CAfile certs/ca.crt certs/client.crt

cluster:
	@kind create cluster --name mtls --config kind.yml --kubeconfig kubeconfig

create: export KUBECONFIG = kubeconfig
create: easysa cluster
	@kubectl get configmap kube-proxy -n kube-system -o yaml | sed -e "s/strictARP: false/strictARP: true/" | sed -e "s/mode: ""/mode: "ipvs"/" | kubectl apply -f - -n kube-system
	@kubectl apply -f manifests/namespace.yaml
	@kubectl create secret generic -n metallb-system memberlist --from-literal=secretkey="$(openssl rand -base64 128)"
	@kubectl apply -f manifests/metallb.yaml
	@kubectl apply -f manifests/metallb-configmap.yml

	@cd playbook/ && ansible-playbook -i inventory.ini --tags all main.yml

destroy:
	@kind delete cluster --name mtls

.PHONY: create
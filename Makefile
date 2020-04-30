PLAY	= ansible-playbook -i .hosts --ssh-common-args "-F .ssh_conf"

.PHONY: install test distclean

.ssh_conf:
	vagrant ssh-config > $@

.hosts:	.ssh_conf
	awk '/^Host /{print $$2,"	  # cri_runtime={docker|docker_latest|containerd}"}' .ssh_conf > $@

install: playbook.yaml .hosts
	$(PLAY) $<

test:	.hosts
	ansible -i .hosts --ssh-common-args "-F .ssh_conf" all -m shell -a '/sbin/ip -4 route get 8.8.8.8'

test-vars:	.hosts
	ansible -i .hosts --ssh-common-args "-F .ssh_conf" all -m setup

distclean:
	vagrant destroy -f
	rm -fr .ssh_conf .hosts .vagrant

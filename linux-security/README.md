# Security

Hardening a linux box

- [open scap](https://www.open-scap.org/) tool enforces a security profiles
- [open scap](https://www.open-scap.org/) tool checks for os vulnerabilities
- [OWASP Dependency Check](https://www.owasp.org/index.php/OWASP_Dependency_Check) checks application dependencies for vulnerabilities
- [vuls](https://vuls.io/) checks for many security vulnerabilities (os,applications, dependencies)

## Open scap security profiles

Start here <https://www.open-scap.org/getting-started/>

Open scap checks if the system respect a specific security profile

Open scap can generate bash and ansible remediation scripts

Chose a policy profile <https://www.open-scap.org/security-policies/choosing-policy/>

Select a profile:

- Install Red Hat profiles `yum install scap-security-guide`
- List profiles `oscap info /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml`

Example profiles:

- Standard System Security Profile for Red Hat Enterprise Linux 7 - Id: `xccdf_org.ssgproject.content_profile_standard`
- Red Hat Corporate Profile for Certified Cloud Providers (RH CCP) - Id: `xccdf_org.ssgproject.content_profile_rht-ccp`

Check:

- `export OSCAP_PROFILE="xccdf_org.ssgproject.content_profile_standard"`
- Check `oscap xccdf eval --fetch-remote-resources --profile "${OSCAP_PROFILE}"  --results-arf arf.xml  --report /tmp/report.html  /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml`
- start a python web server to see report ...
- Generate ansible fix `oscap xccdf generate fix --fix-type ansible --profile "${OSCAP_PROFILE}" --output stig-rhel7-role.yml /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml`
- run ansible fix `ansible-playbook --connection=local --inventory 127.0.0.1, stig-rhel7-role.yml`

A full example in [vagrant/ansible](vagrant/ansible)

CIS (Center for Internet Security ) publishes compliance profiles <https://oval.cisecurity.org/repository/download/5.11.2/compliance> but they don't include remediation script.

## Open scap os vulnerabilities

CIS (Center for Internet Security ) oval profiles <https://oval.cisecurity.org/repository/download>

- download cis oval profile for centos7 `curl -O https://oval.cisecurity.org/repository/download/5.11.2/vulnerability/centos_linux_7.xml`
- evaluate oval script `oscap oval eval --results results-oval.xml --report oval-report.html centos_linux_7.xml`

A full example in [vagrant/ansible](vagrant/ansible)

## OWASP Dependency Check

To do...

## Vuls

[vuls](https://vuls.io/) checks for many security vulnerabilities (os,applications, dependencies)

## Resources

- <https://github.com/ComplianceAsCode/content>
- Generate ansible fix <https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/security_guide/sect-using_openscap_with_ansible>
- scan for vulnerabilities <http://static.open-scap.org/openscap-1.2/oscap_user_manual.html#_auditing_security_vulnerabilities_of_red_hat_products>

## Ansible

- Vagrant supports ansible provisioner
- Vagrant generate an inventory files in `.vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory`
- This inventory works from local terminal `export ANSIBLE_HOST_KEY_CHECKING=False  && ansible-playbook -i .vagrant/provisioners/ansible/inventory/vagrant_ansible_inventory ansible/ping.yml`

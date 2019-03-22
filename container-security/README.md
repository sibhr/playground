# Security

## Open scap

Start here <https://www.open-scap.org/getting-started/>

- List profiles `oscap info /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml`
- Check `oscap xccdf eval  --profile xccdf_org.ssgproject.content_profile_rht-ccp  --results-arf arf.xml  --report report.html  /usr/share/xml/scap/ssg/content/ssg-centos7-ds.xml`
- start a python web server to see report ...

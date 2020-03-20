pipeline.yml: template.yml
	ytt -f $< > $@

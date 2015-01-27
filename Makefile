BASE = .
SYNCDIRS = lib data vocab
ALL = 

sync-deploy: deploy
	rsync -avzc --delete deploy/. $(DEPLOY_DEST)

clean:
	rm -f *~ ; \
	@for dir in $(SYNCDIRS); do $(MAKE) -C $$dir clean; done

.PHONY: sync-deploy

include $(BASE)/Makefile.vars
include $(BASE)/Makefile.in

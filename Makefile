BASE = .
SYNCDIRS = lib data vocab
ALL = 

include $(BASE)/Makefile.vars

sync-deploy: deploy
	rsync -avzc $(RSYNC_PARAMS) deploy/. $(DEPLOY_DEST)

clean:
	rm -f *~ ; \
	@for dir in $(SYNCDIRS); do $(MAKE) -C $$dir clean; done

.PHONY: sync-deploy

include $(BASE)/Makefile.in

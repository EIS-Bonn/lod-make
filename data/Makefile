BASE           = ..
# PUB_SYNCFILES  = registry-expanded.ttl registry.rdf registry.ttl README
WORK_SYNCFILES = 
SYNCDIRS       =

# VOCAB_INFERENCES       = $(LIB)/dol-inferences-beyond-owl.n3
OWL_INFERENCES       = $(LIB)/some-owl-inferences.n3
EYEBALL_FIXES	     = eyeball-fixes.rdf # some things eyeball reports missing, even though they actually exist

include $(BASE)/Makefile.vars
include $(BASE)/Makefile.in
include Makefile.vars
include ../vocab/Makefile.in

DEPLOY_FILES         = $(DATASET) $(DEPLOY_OTHER)
EXPANDED_DATASET     = $(DATASET:.rdf=-expanded.nt)
EYEBALL_DEFAULT_ARGS = -assume $(foreach vocab,$(DATA_VOCABS) $(OTHER_VOCABS),-assume $(vocab)) -assume $(OWL) -assume $(EYEBALL_FIXES)

all: $(DEPLOY_FILES)

# Eyeball must be last, as it usually fails
test: $(DATASET:.rdf=-with-tbox.rdf) $(DATASET:.rdf=.eyeball)

# validate RDF with Eyeball
%.eyeball: %.rdf
	eyeball $(EYEBALL_DEFAULT_ARGS) -check $<

# Dataset TBox (the OWL ontology that defines the vocabulary of the graph) and ABox (the actual graph) combined, for the purpose of validating (manually, known to work with HermiT in Protégé 4.1) whether the ABox is consistent wrt. the TBox.
$(DATASET:.rdf=-with-tbox.rdf): $(EXPANDED_DATASET) $(DATA_VOCABS)
	cwm --n3 $< --rdf $(DATA_VOCABS) > $@

# 1. apply the N3 ruleset to expand the core dataset to the expanded dataset; in detail:
#    cwm --n3 $<                      # parse the input as N3 (a superset of Turtle)
#    --rdf ...                        # parse the vocabularies as RDF/XML
#    --n3 $(VOCAB_INFERENCES)         # load vocabulary-specific inference rules (e.g. such inferences that can't be represented in OWL, but only in FOL)
#    $(OWL_INFERENCES)                # load general OWL (and RDFS and RDF) inference rules (just a relevant subset of the actual rules, implemented ad hoc according to our needs)
#    --think                          # apply the inference rules until they lead to no more expansions
#    --ntriples                       # create N-Triples output for easy linewise post-processing
#    $(CWM_DEFAULT_ARGS)
# 2. remove leading whilespace
# 3. filter out any triples whose subjects are not from the namespace of this dataset.  This includes blank nodes, which are just used for editorial comments so far
# 4. filter out triples containing blank nodes in any component.  Many blank nodes are not relevant for the dataset (e.g. artifacts from the RDF serialization of the OWL ontology, editorial comments, etc.), and those, that are, are not supported by our approach.
# 5. filter out triples with certain annotation properties (here: editorial comments)
# 
# TODO blank nodes should actually be supported (and merged into their non-blank predecessors in the graph)
%-expanded.nt: %.ttl $(VOCAB_INFERENCES) $(OWL_INFERENCES)
	cwm --n3 $< $(if,$(DATA_VOCABS) $(OTHER_VOCABS),--rdf $(DATA_VOCABS) $(OTHER_VOCABS)) --n3 $(VOCAB_INFERENCES) $(OWL_INFERENCES) --think --ntriples $(CWM_DEFAULT_ARGS) \
	| perl -pe 's/^[[:space:]]*//' \
        | grep '^<$(subst .,\.,$(DATA_NS))' \
	| grep -vE '^<[^>]+>[^<]+(_:|<http://example\.org/todo#)' \
	> $@

# convert expanded N-Triples datasets to Turtle
%-expanded.ttl: %-expanded.nt
	cwm --n3=tv $< > $@

# Output all distinct subject URIs (and blank node IDs) that occur in the dataset.
resource-uris: $(EXPANDED_DATASET)
	awk '{print gensub("<([^>]+)>", "\\1", 1, $$1)}' $< \
	| sort \
	| uniq \
	> $@

# Make sure that all directories exist in whose paths we have resources.
# Skip any namespaces we are not interested in deploying.
$(DEPLOY_DIR)/.dirs: resource-uris
	perl -lne 'print $$1 if m@^$(subst .,\.,$(DATA_NS))((?:[^/]+/)*)[^/]+@' $< \
	| sort \
	| uniq \
	| while read directory ; do \
		echo $$directory ; \
		target=$(DEPLOY_DIR)/$$directory ; \
		$(MKDIR) $$target ; \
		cp .htaccess $$target ; \
	  done && \
	touch $@

# Generate all split files.  Put fragment URIs into their "parent" files.
# The "uniq" below works because the file is still dorted.
# For each resource, …
# 1. read all triples having this resource as a subject
# 2. output them to a self-contained RDF/XML file named after the resource
$(DEPLOY_DIR)/.files: resource-uris $(DEPLOY_DIR)/.dirs
	function do_split() { \
		resource_pattern=$$1 ; \
		main_resource=$$2 ; \
		out_file=$(DEPLOY_DIR)/$${main_resource#$(DATA_NS)} ; \
		[[ -d $$out_file ]] && out_file=$${out_file}/index ; \
		grep -E "$${resource_pattern}" $(EXPANDED_DATASET) \
		| cwm --n3 --rdf $(CWM_DEFAULT_ARGS) \
		> $${out_file}.rdf ; \
	} ; \
	sed 's/#.*//g' $< \
	| uniq \
	| while read resource ; do \
		echo $$resource ; \
		do_split "^<$$resource(#.*)?>" $$resource ; \
	done && \
	touch $@

clean: clean-deploy
	rm -rf $(EXPANDED_DATASET)

clean-deploy:
	rm -rf $(DEPLOY_FILES) $(DEPLOY_DIR)/*

.PHONY: all test clean clean-deploy

#
# Build mock and local RPM versions of tools
#

# Assure that sorting is case sensitive
LANG=C

MOCKS+=epel-6-i386
#MOCKS+=epel-5-i386
#MOCKS+=epel-4-i386

MOCKS+=epel-6-x86_64
MOCKS+=epel-5-x86_64
#MOCKS+=epel-4-x86_64

SPEC := `ls *.spec | head -1`
PKGNAME := "`ls *.spec | head -1 | sed 's/.spec$$//g'`"

REPOBASEDIR=/var/www/mirrors/javarepo

all:: verifyspec $(MOCKS)

# Oddness to get deduced .spec file verified
verifyspec:: FORCE
	@if [ ! -e $(SPEC) ]; then \
	    echo Error: SPEC file $(SPEC) not found, exiting; \
	    exit 1; \
	fi

srpm:: verifyspec FORCE
	@echo "Building SRPM with $(SPEC)"
	rm -f $(PKGNAME)*.src.rpm
	rpmbuild --define '_sourcedir $(PWD)' \
		--define '_srcrpmdir $(PWD)' \
		-bs $(SPEC) --nodeps

build:: srpm FORCE
	rpmbuild --rebuild `ls *.src.rpm | grep -v ^epel-`

$(MOCKS):: verifyspec FORCE
	@if [ -e $@ -a -n "`find $@ -name \*.rpm`" ]; then \
		echo "Skipping RPM populated $@"; \
	else \
		echo "Building $@ RPMS with $(SPEC)"; \
		rm -rf $@; \
		mock -q -r $@ --sources=$(PWD) \
		    --resultdir=$(PWD)/$@ \
		    --buildsrpm --spec=$(SPEC); \
		echo "Storing $@/*.src.rpm in $@.rpm"; \
		/bin/mv $@/*.src.rpm $@.src.rpm; \
		echo "Actally building RPMS in $@"; \
		rm -rf $@; \
		mock -q -r $@ \
		     --resultdir=$(PWD)/$@ \
		     $@.src.rpm; \
	fi

mock:: $(MOCKS)

clean::
	rm -rf $(MOCKS)

realclean distclean:: clean
	rm -f *.src.rpm

install:: $(MOCKS)
	@for repo in $(MOCKS); do \
	    echo Installing $$repo; \
	    echo "$$repo" | awk -F- '{print $$2,$$3}' | while read yumrelease yumarch; do \
		rpmdir=$(REPOBASEDIR)/$$yumrelease/$$yumarch; \
		srpmdir=$(REPOBASEDIR)/$$yumrelease/SRPMS; \
		echo "Pushing SRPMS to $$srpmdir"; \
		sudo rsync -av $$repo/*.src.rpm --no-owner --no-group $$repo/*.src.rpm $$srpmdir/. || exit 1; \
		sudo createrepo -q $$srpmdir/.; \
		echo "Pushing RPMS to $$rpmdir"; \
		sudo rsync -av $$repo/*.rpm --exclude=*.src.rpm --exclude=*debuginfo*.rpm --no-owner --no-group $$repo/*.rpm $$rpmdir/. || exit 1; \
		sudo createrepo -q $$rpmdir/.; \
	    done; \
	    echo "Deleting /var/cache/mock/$$repo/to clear cache"; \
	    sudo rm -rf /var/cache/mock/$$repo/; \
	done

FORCE:

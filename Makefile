### Na maszynie www.gust.org.pl: svnadmin create /Data/svn/hr_punio
###

ZFILE="Flickr"

all:
	echo make update.kb or install
geo: 2utf
	perl flickr_setGeoLoc.pl hr.icio.ph #> icio-geo.log

update.kb:
	flickr_getsets && flickr_getalltags && \
	cd ~/.knows &&  make 2flicker

# to samo co wy¿ej + ¶ci±ga katalog wszystkich (publicznych) zdjêæ
xupdate.kb: update.kb
	perl flickr_getphotolist.pl -u hr.icio

magic:
	iconv -f iso-8859-2 -t utf-8 magic-tags.pl > magic-tags.utf8


2utf:
	iconv -f iso-8859-2 -t utf-8 flickr_setGeoLoc.pl > flickr_setGeoLoc.pl8

install:
	cp -f flickr_getsetsinfo.pl flickr_getsets.pl flickr_upld.pl flickr_utils.rc \
		flickr_xload.pl login2flickr.rc flick2flickr.pl flickr_getgroups.pl  \
		flickr_getphotolist.pl photo_exif.pl exif_datetime.pl kml-adjust-urls.pl \
		flickr_getalltags.pl flickr_xml2el.pl gps_print_to_photo.pl flickr_photo_recent.pl \
		 /usr/local/lib/perl5/site_perl/ && \
		chmod +rx /usr/local/lib/perl5/site_perl/*pl && \
		chown tomek:tomek ~tomek/.flickr/*
	cp -f flickr_photo_urls.pl /usr/local/bin/flickr_photo_urls
	cp -f flickr_update_kb My-photo-sync.sh photo_thumb.sh My-get-GPX.sh \
		My-gps-reduce-track.sh /usr/local/bin/
		##cp -f ../flickrrc ~tomek/.flickr/ && \

dist:
	rm -rf $(ZFILE).zip *.phtml
	svn ci -m 'aktualizacja' && \
	zip $(ZFILE).zip * && \
	scp -B $(ZFILE).zip tomasz@gnu.univ.gda.pl:Download/$(ZFILE).zip && \
		ssh tomasz@gnu.univ.gda.pl 'cd Download && unzip -o -d ../public_html/prog/scripts/flickr/scripts Flickr.zip ; \
			chmod o+r ../public_html/prog/scripts/flickr/scripts/* ;\
			cp ../public_html/prog/scripts/flickr/scripts/*.html ../public_html/prog/scripts/flickr/ ; \
			chmod o+r ../public_html/prog/scripts/flickr/ '
		rm -rf $(ZFILE).zip



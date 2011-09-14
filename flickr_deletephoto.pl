#!/usr/bin/perl -s
# see: http://flickr.com/groups/api/discuss/74108/
use Flickr::API;

# setup api_key, sharedsecret, auth_token, photo_id here...

my $api = new Flickr::API({key => $api_key, secret => $sharedsecret});

my $res = $api->execute_method('flickr.groups.pools.remove', {
	group_id => $group_id,
        photo_id => $photo_id,
        auth_token => $auth_token }
);

print "$res->{error_message}\n" if !$res->{success};

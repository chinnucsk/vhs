-module (vhs_test).
-include_lib ("etest/include/etest.hrl").
-include_lib ("etest_http/include/etest_http.hrl").
-compile (export_all).

%% vhs:configure should fail with a non-supported adapter
test_configure_with_unsupported_adapter() ->
  ?assert_throw(adapter_not_supported,
                vhs:configure(adapter_not_supported, [])).

%% vhs:configure should work for ibrowse
test_configure_with_ibrowse_adapter() ->
  ?assert_no_throw(adapter_not_supported,
                   vhs:configure(ibrowse, [])).

%% vhs:use_cassete should save all the request-responses into the tape file
test_recording_a_call_with_ibrowse_adapter() ->
  ibrowse:start(),
  vhs:configure(ibrowse, []),
  vhs:use_cassette(iana_domain_test,
                   fun() ->
                       ibrowse:send_req("http://www.iana.org/domains/example/", [], get),
                       [{Request, Response}] = vhs:server_state(),
                       ?assert_equal(Request, ["http://www.iana.org/domains/example/", [], get]),
                       ?assert_equal(Response, {ok,"302",
                                                [{"Server","Apache/2.2.3 (CentOS)"},
                                                 {"Location","/domains/reserved"},
                                                 {"Content-Type","text/html; charset=iso-8859-1"},
                                                 {"Content-Length","201"},
                                                 {"Accept-Ranges","bytes"},
                                                 {"Date","Mon, 15 Jul 2013 15:11:10 GMT"},
                                                 {"X-Varnish","23394050 23393910"},
                                                 {"Age","20"},
                                                 {"Via","1.1 varnish"},
                                                 {"Connection","keep-alive"}],
                                                "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n<html><head>\n<title>302 Found</title>\n</head><body>\n<h1>Found</h1>\n<p>The document has moved <a href=\"/domains/reserved\">here</a>.</p>\n</body></html>\n"})
                   end),

  %% Cleans the state of the server after the block is executed
  ?assert_equal([], vhs:server_state()),

  %% It should have the nice side-effect of creating a new file
  {ok, [StoredCalls]} = file:consult("/tmp/iana_domain_test"),

  %% The number of stored calls should correspond to the calls done inside of the block.
  ?assert_equal(1, length(StoredCalls)),
  ok.

%% vhs:use_cassete should save all the request-responses into the tape file
test_invariants_when_no_call_is_performed() ->
  ibrowse:start(),
  vhs:configure(ibrowse, []),
  vhs:use_cassette(another_call,
                   fun() ->
                       ?assert_equal([], vhs:server_state())
                   end),

  %% Cleans the state of the server after the block is executed
  ?assert_equal([], vhs:server_state()),

  %% It should have the nice side-effect of creating a new file
  {ok, [[]]} = file:consult("/tmp/another_call"),
  ok.

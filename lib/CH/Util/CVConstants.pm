package CH::Util::CVConstants;

use CH::Perl;
use CH::Util::CVConstants::Value;
use Mojo::Base 'Mojolicious::Plugin';
use Readonly;

has 'app';
our $compiled = 0;

# Stores data from cvconstants.yml on API (populated by ChGovUk::Plugins::CVConstants)
our %lookup_data = ();


# Called when you 'use' this module
sub import {
    my ($class) = @_;

    if(!$CH::Util::CVConstants::compiled) {
        my %table = %$CH::Util::CVConstants::cv_table;

        for my $class (keys %table) {
            my $class_key = uc $class;
            my $class_id = $table{$class}->{class_id};

            my $class_const = 'CV::CLASS::' . $class_key;
            eval "Readonly \$$class_const => $class_id" if $class_id;

            for my $value (keys %{$table{$class}}) {
                next if $value eq 'class_id';
                my $value_key = uc $value;
                my $value_id;
                if(ref($table{$class}->{$value})) {
                    $value_id = $table{$class}->{$value}->id;
                } else {
                    $value_id = $table{$class}->{$value};
                }

                my $const = 'CV::' . $class_key . '::' . $value_key;
                eval "Readonly \$$const => '$value_id'";
            }
        }

        $CH::Util::CVConstants::compiled = 1;
    }
    return;
}

# ------------------------------------------------------------------------------ 

sub lookup {
    my ($app, $class, $id) = @_;
    return $lookup_data{$class}->{$id};
}

# ------------------------------------------------------------------------------

our $cv_table = {
codstat => {
    class_id => 25,
        form     => 3,
        transe   => 8,
        live     => 1,
        r        => 7,
        rem      => 6,
        prop     => 4,
        proptr   => 12,
        conv     => 10,
        diss     => 2,
        propse   => 9,
        liq      => 5,
        trangb   => 11,
    },
    xmlgw => {
        class_id     => 2,
        restrictions => 3, #  Service restrictions per authenticated user
        rps          => 1, #  Max requests per Second
    },
    countries => {
        class_id => 404,
    },
    frssestatement => {
        class_id => 85,
    },
    monstate => {
        class_id => 61,
        renew    => 2,
        new      => 1,
        stable   => 0,
    },
    dcat => {
        class_id        => 16,
        con             => 7,
        ddets           => 40,  #  Director Details
        monitor_renew   => 57,
        smdet           => 44,  #  Mort Details (Single)
        crec            => 25,
        bshar_ch        => 31,
        cert_mort       => 644,
        cert_misc       => 649,
        packbb          => 105,
        packj           => 114,
        mort            => 4,
        packd           => 110,
        dtir_pp         => 30,
        bshar           => 15,
        didx            => 39,  #  Director Index
        scud_287        => 259,
        msta            => 12,  #  Mort Statement (Report B)
        363             => 1,
        cert_287        => 643,
        dirrep          => 36,
        guidance        => 27,
        numidx          => 35,
        cert_sd         => 16,  #  Depricated
        cert_cap        => 648,
        worksheet       => 55,  #  Vertex Internal Worksheets
        brch            => 37,
        wsrch           => 14,
        liq             => 5,
        img_cap         => 136,
        scud_288        => 258,
        cert_acc        => 640, #  IMG_* ORed with MAKE_CERT
        packcb          => 107,
        img_288         => 130,
        fmidx           => 45,  #  Mort Index   (Full)
        make_cert       => 512, #  convert DCAT to DCAT_CERT_*
        mreg            => 11,  #  A Mortgage Register
        fmdet           => 46,  #  Mort Details (Full)
        packfb          => 113,
        dddets          => 42,  #  Disq Dir Details
        packad          => 103,
        scud_acc        => 256, #  OR with MAKE_SCUD
        cert_con        => 647,
        ssrch           => 13,
        archive_dvd     => 67,  # added for the switch from archive fiche to archive DVD.
        dvd_rom         => 64,
        cert_os         => 17,  #  Depricated
        cert_newc       => 646,
        scud_cap        => 264,
        cert_liq        => 645,
        img_newc        => 134,
        jobsheet        => 17,  #  Use with CV_DCAT_MAKE_CERT to order Certificates
        additional      => 61,
        acc_363         => 58,  #  [FALSE] Combination product for Webcheck. This
        cap             => 8,
        appoint         => 34,
        packac          => 102,
        filing_pdf      => 65,
        memorandum      => 68,
        packcd          => 109,
        img_acc         => 128, #  OR with MAKE_IMAGE
        non_image_mask  => 127, #  A mask to convert DCAT_IMG to DCAT
        cert_jobsheet   => 529, #  JOBSHEET   | MAKE_CERT
        packca          => 106,
        cert_additional => 573, #  ADDITIONAL | MAKE_CERT
        img_misc        => 137,
        '288b'          => 51,
        packfa          => 112,
        scud_con        => 263,
        misc            => 9,
        shuttlerep      => 63,  #  shuttle data report
        cert_363        => 641,
        dtir_ch         => 32,
        oseas           => 38,
        scud_newc       => 262,
        cert_288        => 642,
        dreg            => 19,
        idx             => 23,
        img_con         => 135,
        pprint          => 59,  #  Kiosk print page
        scud_liq        => 261,
        acc             => 0,
        bulk_forms      => 53,  #  Vertex Bulk Forms
        smidx           => 43,  #  Mort Index   (Single)
        '287'           => 3,
        img_287         => 131,
        scud_misc       => 265,
        dtir            => 20,
        monitor         => 56,
        ddidx           => 41,  #  Disq Dir Index
        packaa          => 100,
        packcc          => 108,
        forms           => 26,
        nici            => 21,
        mdet            => 10,
        scud_363        => 257,
        '288a'          => 50,
        img_mort        => 132,
        lp              => 24,
        newc            => 6,
        '288c'          => 52,
        img_liq         => 133,
        packab          => 101,
        cert_lp         => 60,
        img_363         => 129,
        fh              => 22,
        diradd          => 49,  #  Director other addresses
        cd              => 33,
        packe           => 111,
        make_image      => 128, #  convert DCAT to DCAT_IMG_*
        arpayment       => 66,
        prac            => 48,
        288             => 2,
        882             => 62,
        make_scud       => 256, #  convert DCAT to DCAT_SCUD_*
        nfiche          => 28,
        packba          => 104,
        bshar_pp        => 29,
        adhoc           => 54,
        cert_ac         => 18,
        insol           => 47,
        scud_mort       => 260,
    },
    currency_legacy => {
        class_id => 200,
    },
    communication => {
        class_id                    => 82,
        reminder_opted_out_last     => 4,
        password_reminder_conf      => 23,
        corporationtax              => 21,
        reminder_shurepsc           => 334, #  Value given by CHIPS
        reminder_activation_done    => 2,
        filing_confirmation         => 25,
        reminder_opted_out          => 3,
        password_reminder_einc      => 24,
        failed_payment              => 20,  #  
        payment_status_notification => 26,  #  Payment provider payment status
        reminder_activation         => 1,
        reminder_accounts           => 31,  #  Value given by CHIPS (REM2A/2B)
        password_reminder           => 22,
        reminder_shurep             => 333, #  Value given by CHIPS
    },
    reorder => {
        class_id        => 14,
        weeded_required => 11,
        wrong_addr      => 3,
        norec_fax       => 2,
        pricing_info    => 12,
        miss_info_image => 5,
        norec_post      => 1,
        miss_info_fiche => 4,
        weeded_on_fiche => 10,
        wrong_comp_lib  => 9,
        wrong_company   => 6,
        illegible_info  => 7,
        other           => 13,
        norec_from_lib  => 8,
    },
    formfee => {
        class_id => 77,
        einc     => 10801,
        nm01     => 11001,
        sdnm04   => 1059580, # 11004 + 2**20,
        llsdnm01 => 1069577, # 21001 + 2**20,
        nm04     => 11002,
        llar01   => 20901,
        llnm01   => 21001,
        ar01     => 10901,
        sdnm01   => 1059577, # 11001 + 2**20,
        form363a => 1363,
    },
    isocountrygbnir => {
        class_id => 413,
    },
    min_sic => {
        class_id => 100,
    },
    isocountrygbukm => {
        class_id => 407,
    },
    doctype => {
        class_id => 56,
        pdf      => 2,
        ps       => 4,
        rtf      => 3,
        none     => 0,
        text     => 1,
        html     => 5,
    },
    apptype => {
        class_id   => 43,
        unknown    => 0,
        persauthr  => 9,
        recman     => 5001,
        persautha  => 8,
        dircorp    => 104,
        memcorp    => 106,
        llplimpart => 6,
        persauthra => 10,
        factor     => 5002,
        eeigman    => 7,
        dirnat     => 103,
        llpdesmem  => 504,
        llpmem     => 3,
        nomdir     => 502,
        secnat     => 101,
        nomsec     => 501,
        llpgenpart => 5,
        memnat     => 105,
        cic        => 5000,
        memcorpdes => 108,
        dir        => 2,
        memnatdes  => 107,
        sec        => 1,
        seccorp    => 102,
    },
    addressval => {
        class_id  => 67,
        lookedup  => 2,
        amended   => 0,
        unchanged => 3,
        foreign   => 1,
    },
    shareclass_max => {
        class_id => 309,
    },
    payvendor => {
        class_id => 92,
        paypal   => 2,
        barclays => 1,
    },
    prescribedparticulars => {
        class_id => 84,
    },
    companycat => {
        class_id      => 74,
        ireland       => 3,
        scotland      => 2,
        other         => 0,
        england_wales => 1,
    },
    bannertext => {
        class_id => 52,
        login    => 1,
        main     => 2,
        setstart => 3,
    },
    dataexplang => {
        class_id => 50,
        current  => 1,
        ebr      => 3,
        english  => 2,
    },
    names => {
        class_id   => 3,
        max_alpha  => 1, #  Max alphakey results to return
        max_number => 2, #  Max numsearch results to return
    },
    accessctrl => {
        class_id => 59,
        monitor  => 1,
    },
    dblock => {
        class_id                 => 42,
        cert                     => 10,
        orderhead                => 1,
        form                     => 4,
        printdoc                 => 5,
        auth                     => 7,
        corporationtax           => 17,
        formresponse             => 11,
        emaildoc                 => 6,
        eremindermatch           => 15,
        communication_weeding    => 18,
        prodhead                 => 2,
        formpartition            => 9,
        formarchive              => 13,
        paymenttx_report         => 20,
        paymenttx_process        => 21,
        faxdoc                   => 3,
        paymenttx_communication  => 19,
        emailresponse            => 12,
        formheader_failedpayment => 16,
        communication            => 14,
        intdoc                   => 8,
    },
    certtype => {
        class_id => 66,
        inc_con  => 2,
        inc      => 1,
        inc_lcon => 3,
        nonexist => 6,
        diss     => 4,
        mort     => 5,
    },
    dmeth => {
        class_id         => 11,
        non_sameday_mask => 4095,
        anon_ftp         => 256,
        post             => 1,
        upload           => 64,
        collect          => 16,
        email            => 4,
        submission       => 512,
        download         => 8,
        online           => 32,
        internal         => 128,
        fax              => 2,
        archive          => 1024,
        make_sameday     => 4096,
    },
    formtype => {
        class_id     => 45,
        llcon        => 21000,
        eremactivate => 4011,
        llmr02       => 21102,
        llch02       => 20202,
        llap02       => 20102,
        chdob        => 10205,
        pr01         => 4001,
        form190a     => 1190,
        form225      => 225,
        rcol         => 10702,
        nm04         => 11004,
        sdnm01       => 1059577,    # 11001 + 2**20,
        mr01         => 11101,
        ap03         => 10103,
        form190      => 190,
        form363a     => 1363,
        aa02         => 10602,
        formccs      => 3,
        nm01         => 11001,
        sail         => 10701,
        sameday      => 1048576,
        auditaccount => 904,
        llar01       => 20901,
        pr02         => 4002,
        ch04         => 10204,
        llmr04       => 21104,
        llap01       => 20101,
        llch01       => 20201,
        mr05         => 11105,
        ad03         => 10403,
        form287      => 287,
        shuttle      => 1,
        llnm01       => 21001,
        webxml       => 536870912,
        ap04         => 10104,
        llaa01       => 20601,
        sdnm04       => 1059580,    # 11004 + 2**20,
        ch03         => 10203,
        form353a     => 1353,
        mr02         => 11102,
        llsdnm01     => 1069577,    # 21001 + 2**20,
        einc         => 10801,
        form882      => 88,
        form363s     => 2363,
        tm01         => 10301,
        aaabbr       => 10603,
        xmlgw        => 1073741824,
        ch02         => 10202,
        aaprefix     => 9,
        ad04         => 10404,
        form288a     => 1288,
        llad04       => 20404,
        llsdeinc     => 20802,
        llmr05       => 21105,
        tm02         => 10302,
        uaaccount    => 901,
        form353      => 353,
        ad02         => 10402,
        llad03       => 20403,
        ap01         => 10101,
        ad01         => 'change-registered-office-address',
        sh01         => 10501,
        erem         => 4010,
        dcaccount    => 902,
        con          => 11000,
        sdeinc       => 10802,
        lleinc       => 20801,
        form123      => 123,
        formgen      => 2,
        form288c     => 3288,
        llad01       => 20401,
        lltm01       => 20301,
        ch01         => 10201,
        cym          => 65536,
        llsail       => 20701,
        abbrvaccount => 903,
        ap02         => 10102,
        aa01         => 10601,
        ar01         => 10901,
        res15        => 11015,
        llmr01       => 21101,
        mr04         => 11104,
        llad02       => 20402,
        form288b     => 2288,
    },
    srvctrl => {
        class_id => 37,
        open     => 2,
        problems => 4,
        current  => 1,
        closed   => 3,
        pending  => 5,
    },
    currency_max => {
        class_id => 226,
    },
    ewfconfig => {
        class_id      => 49,
        maxofficers   => 1,
        recentfilings => 2,
    },
    render => {
        class_id => 8,
        current  => 1,
        stdchd   => 2,
    },
    monitor => {
        class_id     => 58,
        renew_period => 1,
        act_period   => 0,
    },
    emailnotify => {
        class_id => 33,
        perm     => 2,
        temp     => 1,
    },
    isocountrygbr => {
        class_id => 407,
    },
    paystat => {
        class_id   => 90,
        capture    => 6,
        authorised => 1,
        pending    => 4,
        refused    => 2,
        error      => 5,
        cancelled  => 3,
    },
    isocountrygbcym => {
        class_id => 411,
    },
    curr => {
        class_id => 23,
        usd      => 4,
        current  => 1,
        eur      => 3,
        gbp      => 2,
    },
    paytxstat => {
        class_id            => 94,
        pending             => 1, #  Newly created
        accept_communicated => 4, #  An "accepted payment" communciation has been sent
        partitioned         => 2, #  Has been partitioned
        reject_communicated => 3, #  A "rejected payment" communciation has been sent
    },
    phonenumber => {
        class_id => 39,
        helpdesk => 1,
    },
    labeltext => {
        class_id => 57,
    },
    cotypeinfo => {
        class_id => 19,
        pnz      => 18,
        pic      => 8,
        psr      => 28,
        pzc      => 30,
        pna      => 11,
        psz      => 29,
        default  => 1,
        pge      => 5,
        psf      => 23,
        poc      => 19,
        psi      => 24,
        psa      => 21,
        pac      => 2,
        pfc      => 4,
        pnl      => 14,
        plp      => 10,
        pno      => 15,
        psl      => 25,
        pnp      => 16,
        pgs      => 7,
        pso      => 26,
        pnr      => 17,
        pnc      => 33,
        prc      => 20,
        pbr      => 3,
        pgn      => 6,
        psp      => 27,
        pro      => 34,
        pse      => 31,
        pnf      => 12,
        pip      => 9,
        psc      => 22,
        pes      => 32,
        pni      => 13,
    },
    notify => {
        class_id  => 38,
        orderfail => 1,
        closed    => 64,
        techfault => 16,
        mmbanner  => 4,
        adminmsg  => 8,
        sobanner  => 2,
        closewarn => 32,
    },
    corpbodytype => {
        class_id     => 75,
        byguarexempt => 5,
        byguar       => 7,
        byshr        => 2,
        llp          => 20,
        plc          => 3,
    },
    mortind => {
        class_id => 69,
    },
    isocountrygbgbn => {
        class_id => 408,
    },
    resoltype => {
        class_id      => 47,
        extraordinary => 2,
        ordinary      => 1,
        special       => 3,
    },
    ulevel => {
        class_id   => 35,
        trial      => 64,
        advanced   => 16,
        bdoor      => 2,
        chic       => 8,
        test       => 32,
        chinternal => 128,
        devel      => 1,
        extranet   => 4,
    },
    failure => {
        class_id => 15,
    },
    personpermission => {
        class_id => 88,
        full     => 4294967295, #  (2**32)-1
    },
    isocountry => {
        class_id => 406,
    },
    chd_nmenu => {
        class_id => 6,
    },
    appsmsg => {
        class_id => 27,
        none     => 3,
    },
    authoriser => {
        class_id   => 80,
        member     => 3,
        subscriber => 1,
        solicitor  => 4,
        agent      => 2,
    },

    ereminders => {
        class_id     => 95,
        registered   => 102,
        unregistered => 105,
        pending      => 106,
    },

    proof => {
        class_id     => 96,
        unregistered => 0,
        registered   => 1,
        pending      => 5, 
    },

    currency_topten => {
        class_id => 44,
    },
    mortchargtype => {
        class_id              => 68,
        part_case             => 4,
        whole_both            => 10,
        whole_release         => 8,
        part_both             => 6,
        outstanding           => 0,
        fully_satisfied       => 1,
        whole_case            => 3,
        part_release          => 5,
        multiple              => 9,
        partially_satisfied   => 2,
        pre_1991_satisfaction => 7,
    },
    mailsubject => {
        class_id                  => 70,
        ereminder_activation      => 15,
        account_reminder_conf     => 24,
        ereminder_accounts        => 13,
        security                  => 4,
        newinc_confirmation       => 8,
        document_order            => 5,
        ereminder_activ_removed   => 17,
        ereminder_shurep          => 14,
        confirmation              => 0,
        account_reminder          => 3,
        ereminder_activ_confirm   => 16,
        filing_reject             => 22,
        failed_payment            => 18,
        newinc_registration       => 11,
        newinc_reminder           => 12,
        filing_accept             => 21,
        filing_confirmation       => 20,
        payment_status_failed     => 26,
        corporationtax            => 19,
        newinc_reject             => 10,
        payment_status_accepted   => 25,
        registration_confirmation => 1,
        fake_from                 => 23,
        document_request          => 6,
        registration_reminder     => 2,
        newinc_accept             => 9,
    },
    cotypedesc => {
        class_id => 18,
        pnr      => 17,
        plp      => 10,
        pno      => 15,
        pnc      => 33,
        pnl      => 14,
        psl      => 25,
        prc      => 20,
        pnp      => 16,
        pbr      => 3,
        pgs      => 7,
        pgn      => 6,
        pso      => 26,
        psp      => 27,
        pro      => 34,
        pse      => 31,
        pnf      => 12,
        pip      => 9,
        psc      => 22,
        pes      => 32,
        pni      => 13,
        pnz      => 18,
        pic      => 8,
        psr      => 28,
        pzc      => 30,
        pna      => 11,
        psz      => 29,
        default  => 1,
        pge      => 5,
        psf      => 23,
        poc      => 19,
        psi      => 24,
        psa      => 21,
        pac      => 2,
        pfc      => 4,
    },
    registerlocation => {
        class_id => 414,
    },
    max_sic => {
        class_id => 152,
    },
    common_nationalities => {
        class_id => 401,
    },
    stylesheet => {
        class_id => 9,
        current  => 1,
        stdchd   => 2,
    },
    custdef => {
        class_id     => 22,
        refmandatory => 2,
        reference    => 1,
    },
    paym => {
        class_id => 12,
        account  => 1,
        none     => 0,
        reorder  => 7,
        stamps   => 4,
        cash     => 6,
        po       => 3,
        card     => 2,
        cheque   => 5,
        prepaid  => 8,
    },
    inconsist => {
        class_id     => 72,
        sail         => 2,
        other        => 999,
        officerslist => 1,
        confirmed    => 1024,
    },
    min_sic07 => {
        class_id => 501,
    },
    xbrl_error => {
        class_id => 64,
    },
    roletype => {
        class_id => 89,
        company  => 1,
        person   => 2,
    },
    isocountrygbsct => {
        class_id => 412,
    },
    document => {
        class_id          => 32,
        suppnameauth      => 12,
        xbrl              => 14,
        monitor           => 8,
        package           => 2,
        deed              => 17,
        supporting        => 11,
        jobsheet          => 7,
        xmlaccount_abbrv  => 16,
        fiche             => 5,
        invoice           => 6,
        fichedoc          => 4,
        package_item      => 128, #  Modifier to indicate package member
        image             => 1,
        xmlaccount        => 9,
        suppexistname     => 13,
        package_base_type => 127, #  Modifier to get base type
        memandarts        => 10,
        report            => 3,
        filing_pdf        => 15,
    },
    lang => {
        class_id => 5,
        french   => 4,
        welsh    => 3,
        current  => 1,
        english  => 2,
    },
    postcountry => {
        class_id => 65,
    },
    chd_cmenu => {
        class_id => 7,
    },
    url => {
        class_id => 40,
        chdexit  => 1,
    },
    occupations => {
        class_id => 403,
    },
    costatus => {
        class_id => 20,
        trangb   => 14,
        reject   => 9,
        liq      => 2,
        propse   => 12,
        diss     => 3,
        conv     => 13,
        default  => 1,
        proptr   => 15,
        prop     => 5,
        effect   => 8,
        rem      => 6,
        transe   => 11,
        special  => 7,
        form     => 4,
        con      => 10,
    },
    escompanytype => {
        class_id                => 95,
        unltd_with_sharecapital => 6,
        unltd_no_sharecapital   => 7,
        byguar                  => 3,
        byshrexempt             => 4,
        plc                     => 1,
        byshr                   => 2,
        llp                     => 20,
        byguarexempt            => 5,
    },
    formcat => {
        class_id   => 73,
        accounts   => 5,
        inc        => 2,
        mortgage   => 6,
        shuttle    => 4,
        samedayinc => 3,
        general    => 1,
    },
    fhistmsg => {
        class_id => 29,
        none     => 3,
    },
    meettype => {
        class_id      => 46,
        annual        => 1,
        extraordinary => 2,
    },
    currency_min => {
        class_id => 201,
    },
    errorstr => {
        class_id => 71,
    },
    sysaudit => {
        class_id      => 63,
        sys_monitor   => 3,
        cgi_threshold => 1,
        image_delay   => 2,
    },
    maximum => {
        class_id => 75,
    },
    priority => {
        class_id => 81,
        low      => 100,
        high     => 1,
        medium   => 50,
    },
    cotypeadd => {
        class_id => 53,
        pnl      => 14,
        plp      => 10,
        pno      => 15,
        psl      => 25,
        pnp      => 16,
        pgs      => 7,
        pso      => 26,
        pnr      => 17,
        pnc      => 33,
        prc      => 20,
        pbr      => 3,
        pgn      => 6,
        psp      => 27,
        pro      => 34,
        pse      => 31,
        pnf      => 12,
        pip      => 9,
        psc      => 22,
        pes      => 32,
        pni      => 13,
        pnz      => 18,
        pic      => 8,
        psr      => 28,
        pzc      => 30,
        pna      => 11,
        psz      => 29,
        default  => 1,
        pge      => 5,
        psf      => 23,
        poc      => 19,
        psi      => 24,
        psa      => 21,
        pac      => 2,
        pfc      => 4,
    },
    srvctrlmsg => {
        class_id   => 54,
        pendingmsg => 1,
    },
    jurisdiction => {
        class_id          => 405,
        northern_ireland  => 4,
        england_and_wales => 1,
        england           => 7,
        eu                => 5,
        wales             => 2,
        foreign_non_eu    => 8,
        scotland          => 3,
        wales_mutated     => 9,
        uk                => 6,
    },
    auth => {
        class_id  => 1,
        extid_len => 3, #  Extranets private key
        md5key    => 2, #  Extranets private key
        max_retry => 1, #  Max Sign on retries
    },
    appctrlswitch => {
        class_id       => 51,
        backupsrv      => 10,
        producescud    => 4,
        producepackage => 6,
        producefiche   => 5,
        producereport  => 2,
        backdetect     => 9,
        allowimage     => 1,
        compression    => 8,
        produceimage   => 3,
        allownetbanx   => 7,
    },
    dstat => {
        class_id            => 13,
        failed_ws_generated => 9,
        emailed             => 5,
        failed_acc2         => 16,
        awaiting_pdf        => 37,
        failed              => 7,
        faxing              => 12,
        awaiting_dispatch   => 11,
        failed_and_actioned => 10,
        failed_data         => 18,
        awaiting_payment    => 20,
        email_complete      => 32,
        pending             => 27,
        downloaded          => 24,
        cancelled           => 41,
        failed_payment      => 35,
        max_retries         => 34,
        inprogress          => 39,
        reprint_invoice     => 23,
        viewed              => 14,
        prematch            => 45,
        polled              => 28,
        rejected            => 26,
        email_failed        => 33,
        posted              => 6,
        sent_to_chips       => 29,
        email_requeued      => 36,
        faxed               => 4,
        failed_system       => 17,
        printed             => 22,
        awaiting_memandarts => 42,
        referred            => 8,
        archived            => 43,
        onhold              => 40,
        failed_acc1         => 15,
        failed_responder    => 30,
        reordered           => 13,
        requeued            => 21,
        awaiting_accounts   => 44,
        accepted            => 25,
        frontend_rejected   => 38,
        complete            => 3,
        failed_fax          => 19,
        failed_transform    => 31,
        superseded          => 46,
        processing          => 2,
        queued              => 1,
    },
    chd_mm => {
        class_id => 4,
    },
    accesstype => {
        class_id => 60,
        rw       => 3,
        rd       => 1,
        wr       => 2,
    },
    limitedbyguarantee => {
        class_id => 86,
    },
    cstat => {
        class_id         => 83,
        cancelled        => 2,
        failed           => 3,
        failed_payment   => 8,
        inprogress       => 1,
        rejected         => 6,
        awaiting_payment => 7,
        accepted         => 5,
        processing       => 4,
    },
    xmlgwservices => {
        class_id                      => 79,
        officerappointment            => 18,
        accountsdatarequest           => 32,
        filinghistory                 => 5,
        accounts                      => 24,
        recordchangeoflocation        => 25,
        increasenominalcapital        => 17,
        officersearch                 => 12,
        document                      => 10,
        documentinfo                  => 9,
        registerofdebentureholder     => 21,
        changeofname                  => 27,
        namesearch                    => 1,
        returnofallotmentshares       => 23,
        companydetails                => 4,
        officerchangedetails          => 19,
        companydatarequest            => 28,
        officerdetails                => 11,
        companyappointments           => 7,
        annualreturn                  => 13,
        companyincorporation          => 16,
        sailaddress                   => 26,
        getdocument                   => 31,
        officerresignation            => 20,
        changeregisteredofficeaddress => 15,
        changeaccountingreferencedate => 14,
        enhancedsearch                => 3,
        registerofmembers             => 22,
        statusack                     => 30,
        mortgages                     => 8,
        numbersearch                  => 2,
        getsubmissionstatus           => 29,
        filinghistoryid               => 6,
    },
    titles => {
        class_id => 400,
    },
    cosearchmsg => {
        class_id  => 26,
        nosamatch => 5,
        nomatch   => 4,
        notfound  => 2,
        invalid   => 1,
        badalpha  => 3,
    },
    esinc_type => {
        class_id   => 48,
        correction => 1,
        electronic => 3,
        paperform  => 2,
        none       => 0,
    },
    pollstatus => {
        class_id         => 78,
        new              => 1,
        acknowledged     => 4,
        polled           => 3,
        internal_failure => 5,
        chips_responded  => 2,
    },
    nationalities => {
        class_id => 402,
    },
    isocountrygbwls => {
        class_id => 411,
    },
    shortdcat => {
        class_id => 34,
    },
    ustatus => {
        class_id => 36,
        susp     => 2,
        live     => 1,
    },
    payevent => {
        class_id     => 91,
        modification => 2,
        other        => 4,
        dispute      => 3,
        payment      => 1,
        unknown      => 5,
    },
    insolve => {
        class_id => 30,
        compliq  => 20,
        recscot  => 21,
        doord    => 10,
        notice   => 15,
        wud      => 1,
        ordsus   => 11,
        adminsd  => 28,
        dor      => 5,
        owud     => 2,
        cease    => 14,
        forinso  => 31,
        admined  => 29,
        insdate  => 9,
        cova     => 25,
        vlcred   => 19,
        pracrel  => 13,
        admin    => 27,
        other    => 26,
        petdate  => 8,
        final    => 16,
        adate    => 3,
        dsowrn   => 6,
        addord   => 24,
        corpvol  => 30,
        aordate  => 4,
        duedis   => 17,
        addred   => 23,
        recman   => 22,
        vlmem    => 18,
        state    => 7,
        appprac  => 12,
    },
    companytype => {
        class_id => 55,
        c8       => 9,
        c3       => 4,
        c9       => 10,
        cc       => 13,
        c2       => 3,
        cl       => 15,
        c0       => 1,
        ca       => 11,
        c6       => 7,
        c5       => 6,
        cd       => 14,
        c7       => 8,
        ce       => 16,
        cb       => 12,
        c1       => 2,
        c4       => 5,
    },
    utype => {
        class_id => 24,
        exttest  => 10,
        testt    => 5,
        chd      => 1,
        extranet => 2,
        chic     => 3,
        orcstaff => 7,
        sdesk    => 6,
        ef       => 4,
        chouse   => 9,
        orcdevel => 8,
    },
    shareclass_min => {
        class_id => 300,
    },
    information => {
        class_id => 31,
        whatsnew => 1,
    },
    paypartition => {
        class_id    => 93,
        process     => 2,
        communicate => 1,
    },
    isocountrygbeaw => {
        class_id => 409,
    },
    chipsresponse => {
        class_id                 => 76,
        company_struck_off       => 4104,
        catastrophic_errror      => 4001,
        rejectable_error         => 4100,
        duplicate_barcode        => 4003,
        min_value                => 4000,
        max_value                => 4199,
        company_not_recognised   => 4101,
        user_not_authenticated   => 4002,
        company_closed_dissolved => 4103,
        company_type_invalid     => 4102,
    },
    isocountrygbeng => {
        class_id => 410,
    },
    companypermission => {
        class_id            => 87,
        can_file_mr_forms   => 2,
        can_file_misc_forms => 1,
        full                => 4294967295, #  (2**32)-1
    },
    dmenu => {
        class_id => 17,
    },
    max_sic07 => {
        class_id => 599,
    },
    cdetailsmsg => {
        class_id => 28,
        none     => 3,
    },
    routing => {
        class_id  => 62,
        european  => 32768,
        backupsrv => 65536,
        none      => 0,
    },
    dloc => {
        class_id => 41,
        chma     => 6,
        chlo     => 5,
        chca     => 2,
        chle     => 4,
        chbi     => 1,
        chsc     => 3,
    },
    ref => {
        class_id    => undef,
        psnum       => 1,
        commidea    => 2,
        wsnum       => 3,
        chdorder    => 4,
        envelope    => 5,
        barcode     => 6,
        xmlenvelope => 7,
    }
};

1;

=head1 NAME

CH::Util::CVConstants

=head1 SYNOPSIS

    use CH::Util::CVConstants;

    # As a Readonly constant
    my $id = $CV::CLASS::CONST;

    # From a helper method
    my $cv = $self->cv->{class}->{const};
    my $value = $cv->value;

    # From a template
    $c.cv.class.class_id;
    $c.cv.class.const;

    $c.cv_lookup('class', 1);

=head2 [HashRef] lookup( $class, $id )

Returns a hashref containing description and value from database lookup of CV
class and id

	@param   class [Sring/Number] CV class ID or name
	@param   id    [Number]       CV id

=head2 [HashRef] lookupByValue( $class, $id, $lang )

Returns a hashref containing description from database lookup of CV
class and value

    @param   class [Sring/Number] CV class ID or name
    @param   val   [Number]       CV value
    @param   lang  [String]       Language (e.g. en/cy)

=cut



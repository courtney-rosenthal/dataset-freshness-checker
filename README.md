Dataset Freshness Chcecker
==========================

This utility checks a dataset published on a Socrata-hosted data portal (such as https://data.austintexas.gov/), determines whether the dataset is _current_ or _stale_, and optionally sends a report via email if the dataset is out of date.

The dataset is specified by its identifer, such as "hjeh-idye". The identifier can be obtained by inspection from the URL for browsing a dataset on the data portal. The **--id** option must be used to specify the dataset it.

A dataset is considered stale if it was last updated more than a specified number of business days ago. The utility uses the US holiday calendar in the ["holidays" gem](https://github.com/alexdunae/holidays).

Normally, this utility inspects the dataset and prints a one-line summary, such as:

    Dataset status: CURRENT
    
The **--verbose** option can be used to print a more detailed report.

The **--notify** option can be used to send the report via email when the dataset is found to be stale. The option can be given multiple times to send the report to multiple recipients.


Usage
-----

    Usage:
      dataset-freshness-checker.rb [OPTION ...]

    Options:
      -i, --id=ID                      Data set id -- this is required
      -s, --site=SITE                  Data portal hostname [default: data.austintexas.gov]
      -m, --maxdays=DAYS               Dataset older than this number of business days considered stale [default: 5]
      -n, --notify=EMAIL               Send report to this email address if dataset stale, repeat option for each recipient
      -v, --verbose                    Display report created during processing
      -M, --mailer=CMD                 Use this program to send mail [default: mailx]
      -h, --help                       Prints this help


Example
-------

    $ ruby dataset-freshness-checker.rb --verbose --id=hjeh-idye --maxdays=3 --notify=chip@unicom.com
    Dataset Id:     hjeh-idye
    Endpoint:       https://data.austintexas.gov/api/views/hjeh-idye
    Name:           Austin Animal Center FY15 Intakes *Updated Hourly*
    Last updated:   2015-04-06 16:31:45 -0500
    Dataset age:    4.1 (calendar days)
    Dataset age:    4.1 (business days)
    Max age:        3.0 (business days)
    Dataset status: STALE
    Notifying chip@unicom.com ...

#!/usr/bin/env raku

constant RESET = "\c[ESCAPE][0m";
constant BOLD = "\c[ESCAPE][1m";
constant RED = "\c[ESCAPE][31m";
constant GREEN = "\c[ESCAPE][32m";
constant YELLOW = "\c[ESCAPE][33m";
constant MAGENTA = "\c[ESCAPE][35m";

sub bold($text) {
    return "{BOLD}{$text}{RESET}";
}

sub red($text) {
    return "{RED}{$text}{RESET}";
}

sub green($text) {
    return "{GREEN}{$text}{RESET}";
}

sub yellow($text) {
    return "{YELLOW}{$text}{RESET}";
}

sub magenta($text) {
    return "{MAGENTA}{$text}{RESET}";
}

my $today = Date.today;
my $date-format = "{$today.month}/{$today.day}/{$today.year.comb[2..*].join}";

my $gituser = $*HOME.add("src/github.com/CSSEGISandData/");
my $repo = $gituser.add("COVID-19/");
if $repo.e {
    chdir $repo;
    run "git", "pull";
} else {
    mkdir $gituser;
    chdir $gituser;
    run "git", "clone", "https://github.com/CSSEGISandData/COVID-19";
    chdir "COVID-19";
}

my @provinces = $repo.add("csse_covid_19_data/csse_covid_19_time_series/time_series_19-covid-Confirmed.csv").lines;
my @dates = @provinces.head.split(",")[4..*];
my $last-date = @dates.tail;

my @canada = @provinces.grep(/Canada/);

my %provinces;

for @canada -> $province {
    my @fields = $province.split(",");
    my $name = @fields[0];
    my @time-series = @fields[4..*];
    %provinces{$name} = @time-series;
}

say "Today is $date-format";
say "Data for $last-date";
for %provinces.sort(*.key) -> $pair {
    my $name = $pair.key;
    my @data = $pair.value.list;
    my $last = @data.tail;
    my $second = @data[*-2];
    my $increase = $last - $second;
    my $percent;
    if $second == 0 {
        $percent = 100;
    } else {
        $percent = 100 * $increase/$second;
    }
    say "{bold($name)}: {$second}→$last +{red($increase)} %{yellow($percent)}";
}

my $total-current = [+] %provinces.map: *.value.tail;
my $total-second = [+] %provinces.map: *.value.list[*-2];
my $total-increase = $total-current - $total-second;
my $total-percent = 100 * $total-increase/$total-second;

say "\n{bold('Total')}: {$total-second}→$total-current +{red($total-increase)} %{yellow($total-percent)}";

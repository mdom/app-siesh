package App::Siesh::Batch;

sub ReadLine { return __PACKAGE__ };

sub new {
	my ($class,@commands) = @_;
	bless \@commands, $class;
}

sub readline {
	my $self = shift;
	return pop @{$self};
}

sub history_expand { }
sub MinLine { }
sub Attribs { }
sub OUT { }
sub IN { }
sub ornaments { }
sub addhistory { }

1;

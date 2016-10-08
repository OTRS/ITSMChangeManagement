# --
# Copyright (C) 2001-2016 OTRS AG, http://otrs.com/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

use strict;
use warnings;
use utf8;

use vars (qw($Self));

my $NotificationObject = $Kernel::OM->Get('Kernel::System::ITSMChange::Notification');

my $Notification = $NotificationObject->_NotificationGet(
    NotificationKey => 'en::Agent::WorkOrder::WorkOrderUpdate',
);

my $NotificationDefault = $Notification->{Subject};

$Notification->{Subject} = $NotificationObject->_NotificationReplaceMacros(
    Type      => 'WorkOrder',
    Text      => $Notification->{Subject},
    Recipient => {},
    UserID    => 1,
    Change    => {
        ChangeNumber => '1234',
    },
    WorkOrder => {
        WorkOrderNumber => 'abcd',
    },
    Data => {
        ChangeBuilder => {
            UserFirstname => 'Tom',
            UserLastname  => 'Tester',
            UserEmail     => 'tt@otrs.com',
        },
    },
    Link => {
        SourceObject => 1,
        TargetObject => 2,
        State        => 'open',
        Type         => 'type',
        Object       => 'obj',
    },
    Language => 'en',
);

my $Notification2 = $NotificationObject->_NotificationGet(
    NotificationKey => 'en::Agent::WorkOrder::WorkOrderUpdate',
);

$Self->Is(
    $Notification2->{Subject},
    $NotificationDefault,
    'NotificationGet caching works correctly!',
);

1;

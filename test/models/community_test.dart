import 'package:flutter_test/flutter_test.dart';
import 'package:new_idea_works/models/community.dart';
import 'package:new_idea_works/models/enums.dart';

void main() {
  group('Community', () {
    late Community community;

    setUp(() {
      community = Community(
        id: 'comm-1',
        name: 'FC Moscow',
        sport: SportCategory.football,
        inviteCode: 'FC1234',
        ownerId: 'owner-1',
        adminIds: ['owner-1', 'admin-2'],
        memberIds: ['member-3', 'member-4'],
      );
    });

    test('isOwner returns true only for owner', () {
      expect(community.isOwner('owner-1'), true);
      expect(community.isOwner('admin-2'), false);
      expect(community.isOwner('member-3'), false);
      expect(community.isOwner('unknown'), false);
    });

    test('isAdmin returns true for admins AND owner', () {
      expect(community.isAdmin('owner-1'), true); // owner is always admin
      expect(community.isAdmin('admin-2'), true);
      expect(community.isAdmin('member-3'), false);
    });

    test('isMember returns true for everyone in community', () {
      expect(community.isMember('owner-1'), true);
      expect(community.isMember('admin-2'), true);
      expect(community.isMember('member-3'), true);
      expect(community.isMember('member-4'), true);
      expect(community.isMember('outsider'), false);
    });

    test('totalMembers counts all unique members', () {
      // owner-1 + admin-2 + member-3 + member-4 = 4
      expect(community.totalMembers, 4);
    });

    test('allMemberIds deduplicates owner in adminIds', () {
      // owner-1 is in both ownerId and adminIds
      final all = community.allMemberIds;
      expect(all.toSet().length, all.length); // no duplicates
      expect(all.length, 4);
    });

    test('canManageBalance — only admins can', () {
      expect(community.canManageBalance('owner-1'), true);
      expect(community.canManageBalance('admin-2'), true);
      expect(community.canManageBalance('member-3'), false);
    });

    test('canManageAdmins — only owner can', () {
      expect(community.canManageAdmins('owner-1'), true);
      expect(community.canManageAdmins('admin-2'), false);
      expect(community.canManageAdmins('member-3'), false);
    });

    test('getUserRole returns correct roles', () {
      expect(community.getUserRole('owner-1'), UserRole.owner);
      expect(community.getUserRole('admin-2'), UserRole.admin);
      expect(community.getUserRole('member-3'), UserRole.player);
      expect(community.getUserRole('outsider'), UserRole.player);
    });

    test('default values when optional params are null', () {
      final c = Community(
        id: 'c',
        name: 'Test',
        sport: SportCategory.football,
        inviteCode: 'T1',
        ownerId: 'o1',
      );
      expect(c.adminIds, isEmpty);
      expect(c.memberIds, isEmpty);
      expect(c.monthlyRent, 100000);
      expect(c.singleGamePrice, 1200);
      expect(c.bankBalance, 0);
      expect(c.logoUrl, isNull);
    });
  });
}

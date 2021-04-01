// ignore_for_file: unused_field,use_raw_strings,prefer_interpolation_to_compose_strings,prefer_adjacent_string_concatenation

import 'auto_format.dart';

/// Commonly used regex patterns. Useful as patterns for [FormatRule].
///
/// The patterns used are based on the regular expressions from Twitter's
/// twitter-text library.
///
/// Ported from https://github.com/twitter/twitter-text/tree/65e7e00da383fb77f5ab7fe3c0dc26b724e14035/js/src/regexp.
///
/// Licensed under Apache 2.0: https://github.com/twitter/twitter-text/blob/65e7e00da383fb77f5ab7fe3c0dc26b724e14035/LICENSE

// Full icense text:
//
// Copyright 2011 Twitter, Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this work except in compliance with the License.
// You may obtain a copy of the License below, or at:
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
//                              Apache License
//                        Version 2.0, January 2004
//                     http://www.apache.org/licenses/
//
// TERMS AND CONDITIONS FOR USE, REPRODUCTION, AND DISTRIBUTION
//
// 1. Definitions.
//
//   "License" shall mean the terms and conditions for use, reproduction,
//   and distribution as defined by Sections 1 through 9 of this document.
//
//   "Licensor" shall mean the copyright owner or entity authorized by
//   the copyright owner that is granting the License.
//
//   "Legal Entity" shall mean the union of the acting entity and all
//   other entities that control, are controlled by, or are under common
//   control with that entity. For the purposes of this definition,
//   "control" means (i) the power, direct or indirect, to cause the
//   direction or management of such entity, whether by contract or
//   otherwise, or (ii) ownership of fifty percent (50%) or more of the
//   outstanding shares, or (iii) beneficial ownership of such entity.
//
//   "You" (or "Your") shall mean an individual or Legal Entity
//   exercising permissions granted by this License.
//
//   "Source" form shall mean the preferred form for making modifications,
//   including but not limited to software source code, documentation
//   source, and configuration files.
//
//   "Object" form shall mean any form resulting from mechanical
//   transformation or translation of a Source form, including but
//   not limited to compiled object code, generated documentation,
//   and conversions to other media types.
//
//   "Work" shall mean the work of authorship, whether in Source or
//   Object form, made available under the License, as indicated by a
//   copyright notice that is included in or attached to the work
//   (an example is provided in the Appendix below).
//
//   "Derivative Works" shall mean any work, whether in Source or Object
//   form, that is based on (or derived from) the Work and for which the
//   editorial revisions, annotations, elaborations, or other modifications
//   represent, as a whole, an original work of authorship. For the purposes
//   of this License, Derivative Works shall not include works that remain
//   separable from, or merely link (or bind by name) to the interfaces of,
//   the Work and Derivative Works thereof.
//
//   "Contribution" shall mean any work of authorship, including
//   the original version of the Work and any modifications or additions
//   to that Work or Derivative Works thereof, that is intentionally
//   submitted to Licensor for inclusion in the Work by the copyright owner
//   or by an individual or Legal Entity authorized to submit on behalf of
//   the copyright owner. For the purposes of this definition, "submitted"
//   means any form of electronic, verbal, or written communication sent
//   to the Licensor or its representatives, including but not limited to
//   communication on electronic mailing lists, source code control systems,
//   and issue tracking systems that are managed by, or on behalf of, the
//   Licensor for the purpose of discussing and improving the Work, but
//   excluding communication that is conspicuously marked or otherwise
//   designated in writing by the copyright owner as "Not a Contribution."
//
//   "Contributor" shall mean Licensor and any individual or Legal Entity
//   on behalf of whom a Contribution has been received by Licensor and
//   subsequently incorporated within the Work.
//
// 2. Grant of Copyright License. Subject to the terms and conditions of
//   this License, each Contributor hereby grants to You a perpetual,
//   worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//   copyright license to reproduce, prepare Derivative Works of,
//   publicly display, publicly perform, sublicense, and distribute the
//   Work and such Derivative Works in Source or Object form.
//
// 3. Grant of Patent License. Subject to the terms and conditions of
//   this License, each Contributor hereby grants to You a perpetual,
//   worldwide, non-exclusive, no-charge, royalty-free, irrevocable
//   (except as stated in this section) patent license to make, have made,
//   use, offer to sell, sell, import, and otherwise transfer the Work,
//   where such license applies only to those patent claims licensable
//   by such Contributor that are necessarily infringed by their
//   Contribution(s) alone or by combination of their Contribution(s)
//   with the Work to which such Contribution(s) was submitted. If You
//   institute patent litigation against any entity (including a
//   cross-claim or counterclaim in a lawsuit) alleging that the Work
//   or a Contribution incorporated within the Work constitutes direct
//   or contributory patent infringement, then any patent licenses
//   granted to You under this License for that Work shall terminate
//   as of the date such litigation is filed.
//
// 4. Redistribution. You may reproduce and distribute copies of the
//   Work or Derivative Works thereof in any medium, with or without
//   modifications, and in Source or Object form, provided that You
//   meet the following conditions:
//
//   (a) You must give any other recipients of the Work or
//       Derivative Works a copy of this License; and
//
//   (b) You must cause any modified files to carry prominent notices
//       stating that You changed the files; and
//
//   (c) You must retain, in the Source form of any Derivative Works
//       that You distribute, all copyright, patent, trademark, and
//       attribution notices from the Source form of the Work,
//       excluding those notices that do not pertain to any part of
//       the Derivative Works; and
//
//   (d) If the Work includes a "NOTICE" text file as part of its
//       distribution, then any Derivative Works that You distribute must
//       include a readable copy of the attribution notices contained
//       within such NOTICE file, excluding those notices that do not
//       pertain to any part of the Derivative Works, in at least one
//       of the following places: within a NOTICE text file distributed
//       as part of the Derivative Works; within the Source form or
//       documentation, if provided along with the Derivative Works; or,
//       within a display generated by the Derivative Works, if and
//       wherever such third-party notices normally appear. The contents
//       of the NOTICE file are for informational purposes only and
//       do not modify the License. You may add Your own attribution
//       notices within Derivative Works that You distribute, alongside
//       or as an addendum to the NOTICE text from the Work, provided
//       that such additional attribution notices cannot be construed
//       as modifying the License.
//
//   You may add Your own copyright statement to Your modifications and
//   may provide additional or different license terms and conditions
//   for use, reproduction, or distribution of Your modifications, or
//   for any such Derivative Works as a whole, provided Your use,
//   reproduction, and distribution of the Work otherwise complies with
//   the conditions stated in this License.
//
// 5. Submission of Contributions. Unless You explicitly state otherwise,
//   any Contribution intentionally submitted for inclusion in the Work
//   by You to the Licensor shall be under the terms and conditions of
//   this License, without any additional terms or conditions.
//   Notwithstanding the above, nothing herein shall supersede or modify
//   the terms of any separate license agreement you may have executed
//   with Licensor regarding such Contributions.
//
// 6. Trademarks. This License does not grant permission to use the trade
//   names, trademarks, service marks, or product names of the Licensor,
//   except as required for reasonable and customary use in describing the
//   origin of the Work and reproducing the content of the NOTICE file.
//
// 7. Disclaimer of Warranty. Unless required by applicable law or
//   agreed to in writing, Licensor provides the Work (and each
//   Contributor provides its Contributions) on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
//   implied, including, without limitation, any warranties or conditions
//   of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or FITNESS FOR A
//   PARTICULAR PURPOSE. You are solely responsible for determining the
//   appropriateness of using or redistributing the Work and assume any
//   risks associated with Your exercise of permissions under this License.
//
// 8. Limitation of Liability. In no event and under no legal theory,
//   whether in tort (including negligence), contract, or otherwise,
//   unless required by applicable law (such as deliberate and grossly
//   negligent acts) or agreed to in writing, shall any Contributor be
//   liable to You for damages, including any direct, indirect, special,
//   incidental, or consequential damages of any character arising as a
//   result of this License or out of the use or inability to use the
//   Work (including but not limited to damages for loss of goodwill,
//   work stoppage, computer failure or malfunction, or any and all
//   other commercial damages or losses), even if such Contributor
//   has been advised of the possibility of such damages.
//
// 9. Accepting Warranty or Additional Liability. While redistributing
//   the Work or Derivative Works thereof, You may choose to offer,
//   and charge a fee for, acceptance of support, warranty, indemnity,
//   or other liability obligations and/or rights consistent with this
//   License. However, in accepting such obligations, You may act only
//   on Your own behalf and on Your sole responsibility, not on behalf
//   of any other Contributor, and only if You agree to indemnify,
//   defend, and hold each Contributor harmless for any liability
//   incurred by, or claims asserted against, such Contributor by reason
//   of your accepting any such warranty or additional liability.
class CommonPatterns {
  CommonPatterns._();

  /// Matches alphanumeric words starting with a hash/pound sign.
  ///
  /// Captured groups are:
  ///
  /// 0. Full hashtag including hash sign.
  /// 1. Hash sign (either # or ＃)
  /// 2. Tag content without leading hash sign.
  ///
  /// Tag content may not contain only numbers.
  static final RegExp hashtag = RegExp(
      '(?<=($_hashtagBoundary))' +
          '($_hashSigns)' + // $2 hash sign
          '(?!\\uFE0F|\\u20E3)' +
          // $3 tag content
          '($_hashtagAlphaNumeric*$_hashtagAlpha$_hashtagAlphaNumeric*)',
      caseSensitive: false);

  /// Matches a valid http or https URL.
  ///
  /// Captured groups are:
  ///
  /// 0. Full URL
  /// 1. Protocol: http:// or https:// (optional)
  /// 2. Domain
  /// 3. Port number without leading colon (optional)
  /// 4. URL path including leading forward slash (optional)
  /// 5. Query string (optional)
  static final RegExp httpUrl = RegExp(
    '(?<=$_validUrlPrecedingChars)' +
        '(https?:\\/\\/)?' + // $1 Protocol (optional)
        '($_validDomain)' + // $2 Domain(s)
        '(?::($_validPortNumber))?' + // $3 Port number (optional)
        '(\\/$_validUrlPath*)?' + // $4 URL Path
        '(\\?$_validUrlQueryChars*$_validUrlQueryEndingChars)?', // $5 Query String
    caseSensitive: false,
  );

  /// Matches patterns that start with @ and are followed by an
  /// alphanumeric (including _) identifier.
  ///
  /// Captured groups are:
  ///
  /// 0. Full mention including at sign
  /// 1. At sign (can be @ or ＠)
  /// 2. Handle without at sign
  static final RegExp mention = RegExp(
    '(?<=$_validMentionPrecedingChars)' +
        '($_atSigns)' + // $1: At mark
        '([a-zA-Z0-9_]+)', // $2: mention handle
  );

  static const String _astralLetterAndMarks =
      r'\ud800[\udc00-\udc0b\udc0d-\udc26\udc28-\udc3a\udc3c\udc3d\udc3f-\udc4d\udc50-\udc5d\udc80-\udcfa\uddfd\ude80-\ude9c\udea0-\uded0\udee0\udf00-\udf1f\udf30-\udf40\udf42-\udf49\udf50-\udf7a\udf80-\udf9d\udfa0-\udfc3\udfc8-\udfcf]|\ud801[\udc00-\udc9d\udd00-\udd27\udd30-\udd63\ude00-\udf36\udf40-\udf55\udf60-\udf67]|\ud802[\udc00-\udc05\udc08\udc0a-\udc35\udc37\udc38\udc3c\udc3f-\udc55\udc60-\udc76\udc80-\udc9e\udd00-\udd15\udd20-\udd39\udd80-\uddb7\uddbe\uddbf\ude00-\ude03\ude05\ude06\ude0c-\ude13\ude15-\ude17\ude19-\ude33\ude38-\ude3a\ude3f\ude60-\ude7c\ude80-\ude9c\udec0-\udec7\udec9-\udee6\udf00-\udf35\udf40-\udf55\udf60-\udf72\udf80-\udf91]|\ud803[\udc00-\udc48]|\ud804[\udc00-\udc46\udc7f-\udcba\udcd0-\udce8\udd00-\udd34\udd50-\udd73\udd76\udd80-\uddc4\uddda\ude00-\ude11\ude13-\ude37\udeb0-\udeea\udf01-\udf03\udf05-\udf0c\udf0f\udf10\udf13-\udf28\udf2a-\udf30\udf32\udf33\udf35-\udf39\udf3c-\udf44\udf47\udf48\udf4b-\udf4d\udf57\udf5d-\udf63\udf66-\udf6c\udf70-\udf74]|\ud805[\udc80-\udcc5\udcc7\udd80-\uddb5\uddb8-\uddc0\ude00-\ude40\ude44\ude80-\udeb7]|\ud806[\udca0-\udcdf\udcff\udec0-\udef8]|\ud808[\udc00-\udf98]|\ud80c[\udc00-\udfff]|\ud80d[\udc00-\udc2e]|\ud81a[\udc00-\ude38\ude40-\ude5e\uded0-\udeed\udef0-\udef4\udf00-\udf36\udf40-\udf43\udf63-\udf77\udf7d-\udf8f]|\ud81b[\udf00-\udf44\udf50-\udf7e\udf8f-\udf9f]|\ud82c[\udc00\udc01]|\ud82f[\udc00-\udc6a\udc70-\udc7c\udc80-\udc88\udc90-\udc99\udc9d\udc9e]|\ud834[\udd65-\udd69\udd6d-\udd72\udd7b-\udd82\udd85-\udd8b\uddaa-\uddad\ude42-\ude44]|\ud835[\udc00-\udc54\udc56-\udc9c\udc9e\udc9f\udca2\udca5\udca6\udca9-\udcac\udcae-\udcb9\udcbb\udcbd-\udcc3\udcc5-\udd05\udd07-\udd0a\udd0d-\udd14\udd16-\udd1c\udd1e-\udd39\udd3b-\udd3e\udd40-\udd44\udd46\udd4a-\udd50\udd52-\udea5\udea8-\udec0\udec2-\udeda\udedc-\udefa\udefc-\udf14\udf16-\udf34\udf36-\udf4e\udf50-\udf6e\udf70-\udf88\udf8a-\udfa8\udfaa-\udfc2\udfc4-\udfcb]|\ud83a[\udc00-\udcc4\udcd0-\udcd6]|\ud83b[\ude00-\ude03\ude05-\ude1f\ude21\ude22\ude24\ude27\ude29-\ude32\ude34-\ude37\ude39\ude3b\ude42\ude47\ude49\ude4b\ude4d-\ude4f\ude51\ude52\ude54\ude57\ude59\ude5b\ude5d\ude5f\ude61\ude62\ude64\ude67-\ude6a\ude6c-\ude72\ude74-\ude77\ude79-\ude7c\ude7e\ude80-\ude89\ude8b-\ude9b\udea1-\udea3\udea5-\udea9\udeab-\udebb]|\ud840[\udc00-\udfff]|\ud841[\udc00-\udfff]|\ud842[\udc00-\udfff]|\ud843[\udc00-\udfff]|\ud844[\udc00-\udfff]|\ud845[\udc00-\udfff]|\ud846[\udc00-\udfff]|\ud847[\udc00-\udfff]|\ud848[\udc00-\udfff]|\ud849[\udc00-\udfff]|\ud84a[\udc00-\udfff]|\ud84b[\udc00-\udfff]|\ud84c[\udc00-\udfff]|\ud84d[\udc00-\udfff]|\ud84e[\udc00-\udfff]|\ud84f[\udc00-\udfff]|\ud850[\udc00-\udfff]|\ud851[\udc00-\udfff]|\ud852[\udc00-\udfff]|\ud853[\udc00-\udfff]|\ud854[\udc00-\udfff]|\ud855[\udc00-\udfff]|\ud856[\udc00-\udfff]|\ud857[\udc00-\udfff]|\ud858[\udc00-\udfff]|\ud859[\udc00-\udfff]|\ud85a[\udc00-\udfff]|\ud85b[\udc00-\udfff]|\ud85c[\udc00-\udfff]|\ud85d[\udc00-\udfff]|\ud85e[\udc00-\udfff]|\ud85f[\udc00-\udfff]|\ud860[\udc00-\udfff]|\ud861[\udc00-\udfff]|\ud862[\udc00-\udfff]|\ud863[\udc00-\udfff]|\ud864[\udc00-\udfff]|\ud865[\udc00-\udfff]|\ud866[\udc00-\udfff]|\ud867[\udc00-\udfff]|\ud868[\udc00-\udfff]|\ud869[\udc00-\uded6\udf00-\udfff]|\ud86a[\udc00-\udfff]|\ud86b[\udc00-\udfff]|\ud86c[\udc00-\udfff]|\ud86d[\udc00-\udf34\udf40-\udfff]|\ud86e[\udc00-\udc1d]|\ud87e[\udc00-\ude1d]|\udb40[\udd00-\uddef]';
  static const String _astralNumerals =
      r'\ud801[\udca0-\udca9]|\ud804[\udc66-\udc6f\udcf0-\udcf9\udd36-\udd3f\uddd0-\uddd9\udef0-\udef9]|\ud805[\udcd0-\udcd9\ude50-\ude59\udec0-\udec9]|\ud806[\udce0-\udce9]|\ud81a[\ude60-\ude69\udf50-\udf59]|\ud835[\udfce-\udfff]';
  static const String _atSigns = '[@＠]';
  static const String _bmpLetterAndMarks =
      r'A-Za-z\xaa\xb5\xba\xc0-\xd6\xd8-\xf6\xf8-\u02c1\u02c6-\u02d1\u02e0-\u02e4\u02ec\u02ee\u0300-\u0374\u0376\u0377\u037a-\u037d\u037f\u0386\u0388-\u038a\u038c\u038e-\u03a1\u03a3-\u03f5\u03f7-\u0481\u0483-\u052f\u0531-\u0556\u0559\u0561-\u0587\u0591-\u05bd\u05bf\u05c1\u05c2\u05c4\u05c5\u05c7\u05d0-\u05ea\u05f0-\u05f2\u0610-\u061a\u0620-\u065f\u066e-\u06d3\u06d5-\u06dc\u06df-\u06e8\u06ea-\u06ef\u06fa-\u06fc\u06ff\u0710-\u074a\u074d-\u07b1\u07ca-\u07f5\u07fa\u0800-\u082d\u0840-\u085b\u08a0-\u08b2\u08e4-\u0963\u0971-\u0983\u0985-\u098c\u098f\u0990\u0993-\u09a8\u09aa-\u09b0\u09b2\u09b6-\u09b9\u09bc-\u09c4\u09c7\u09c8\u09cb-\u09ce\u09d7\u09dc\u09dd\u09df-\u09e3\u09f0\u09f1\u0a01-\u0a03\u0a05-\u0a0a\u0a0f\u0a10\u0a13-\u0a28\u0a2a-\u0a30\u0a32\u0a33\u0a35\u0a36\u0a38\u0a39\u0a3c\u0a3e-\u0a42\u0a47\u0a48\u0a4b-\u0a4d\u0a51\u0a59-\u0a5c\u0a5e\u0a70-\u0a75\u0a81-\u0a83\u0a85-\u0a8d\u0a8f-\u0a91\u0a93-\u0aa8\u0aaa-\u0ab0\u0ab2\u0ab3\u0ab5-\u0ab9\u0abc-\u0ac5\u0ac7-\u0ac9\u0acb-\u0acd\u0ad0\u0ae0-\u0ae3\u0b01-\u0b03\u0b05-\u0b0c\u0b0f\u0b10\u0b13-\u0b28\u0b2a-\u0b30\u0b32\u0b33\u0b35-\u0b39\u0b3c-\u0b44\u0b47\u0b48\u0b4b-\u0b4d\u0b56\u0b57\u0b5c\u0b5d\u0b5f-\u0b63\u0b71\u0b82\u0b83\u0b85-\u0b8a\u0b8e-\u0b90\u0b92-\u0b95\u0b99\u0b9a\u0b9c\u0b9e\u0b9f\u0ba3\u0ba4\u0ba8-\u0baa\u0bae-\u0bb9\u0bbe-\u0bc2\u0bc6-\u0bc8\u0bca-\u0bcd\u0bd0\u0bd7\u0c00-\u0c03\u0c05-\u0c0c\u0c0e-\u0c10\u0c12-\u0c28\u0c2a-\u0c39\u0c3d-\u0c44\u0c46-\u0c48\u0c4a-\u0c4d\u0c55\u0c56\u0c58\u0c59\u0c60-\u0c63\u0c81-\u0c83\u0c85-\u0c8c\u0c8e-\u0c90\u0c92-\u0ca8\u0caa-\u0cb3\u0cb5-\u0cb9\u0cbc-\u0cc4\u0cc6-\u0cc8\u0cca-\u0ccd\u0cd5\u0cd6\u0cde\u0ce0-\u0ce3\u0cf1\u0cf2\u0d01-\u0d03\u0d05-\u0d0c\u0d0e-\u0d10\u0d12-\u0d3a\u0d3d-\u0d44\u0d46-\u0d48\u0d4a-\u0d4e\u0d57\u0d60-\u0d63\u0d7a-\u0d7f\u0d82\u0d83\u0d85-\u0d96\u0d9a-\u0db1\u0db3-\u0dbb\u0dbd\u0dc0-\u0dc6\u0dca\u0dcf-\u0dd4\u0dd6\u0dd8-\u0ddf\u0df2\u0df3\u0e01-\u0e3a\u0e40-\u0e4e\u0e81\u0e82\u0e84\u0e87\u0e88\u0e8a\u0e8d\u0e94-\u0e97\u0e99-\u0e9f\u0ea1-\u0ea3\u0ea5\u0ea7\u0eaa\u0eab\u0ead-\u0eb9\u0ebb-\u0ebd\u0ec0-\u0ec4\u0ec6\u0ec8-\u0ecd\u0edc-\u0edf\u0f00\u0f18\u0f19\u0f35\u0f37\u0f39\u0f3e-\u0f47\u0f49-\u0f6c\u0f71-\u0f84\u0f86-\u0f97\u0f99-\u0fbc\u0fc6\u1000-\u103f\u1050-\u108f\u109a-\u109d\u10a0-\u10c5\u10c7\u10cd\u10d0-\u10fa\u10fc-\u1248\u124a-\u124d\u1250-\u1256\u1258\u125a-\u125d\u1260-\u1288\u128a-\u128d\u1290-\u12b0\u12b2-\u12b5\u12b8-\u12be\u12c0\u12c2-\u12c5\u12c8-\u12d6\u12d8-\u1310\u1312-\u1315\u1318-\u135a\u135d-\u135f\u1380-\u138f\u13a0-\u13f4\u1401-\u166c\u166f-\u167f\u1681-\u169a\u16a0-\u16ea\u16f1-\u16f8\u1700-\u170c\u170e-\u1714\u1720-\u1734\u1740-\u1753\u1760-\u176c\u176e-\u1770\u1772\u1773\u1780-\u17d3\u17d7\u17dc\u17dd\u180b-\u180d\u1820-\u1877\u1880-\u18aa\u18b0-\u18f5\u1900-\u191e\u1920-\u192b\u1930-\u193b\u1950-\u196d\u1970-\u1974\u1980-\u19ab\u19b0-\u19c9\u1a00-\u1a1b\u1a20-\u1a5e\u1a60-\u1a7c\u1a7f\u1aa7\u1ab0-\u1abe\u1b00-\u1b4b\u1b6b-\u1b73\u1b80-\u1baf\u1bba-\u1bf3\u1c00-\u1c37\u1c4d-\u1c4f\u1c5a-\u1c7d\u1cd0-\u1cd2\u1cd4-\u1cf6\u1cf8\u1cf9\u1d00-\u1df5\u1dfc-\u1f15\u1f18-\u1f1d\u1f20-\u1f45\u1f48-\u1f4d\u1f50-\u1f57\u1f59\u1f5b\u1f5d\u1f5f-\u1f7d\u1f80-\u1fb4\u1fb6-\u1fbc\u1fbe\u1fc2-\u1fc4\u1fc6-\u1fcc\u1fd0-\u1fd3\u1fd6-\u1fdb\u1fe0-\u1fec\u1ff2-\u1ff4\u1ff6-\u1ffc\u2071\u207f\u2090-\u209c\u20d0-\u20f0\u2102\u2107\u210a-\u2113\u2115\u2119-\u211d\u2124\u2126\u2128\u212a-\u212d\u212f-\u2139\u213c-\u213f\u2145-\u2149\u214e\u2183\u2184\u2c00-\u2c2e\u2c30-\u2c5e\u2c60-\u2ce4\u2ceb-\u2cf3\u2d00-\u2d25\u2d27\u2d2d\u2d30-\u2d67\u2d6f\u2d7f-\u2d96\u2da0-\u2da6\u2da8-\u2dae\u2db0-\u2db6\u2db8-\u2dbe\u2dc0-\u2dc6\u2dc8-\u2dce\u2dd0-\u2dd6\u2dd8-\u2dde\u2de0-\u2dff\u2e2f\u3005\u3006\u302a-\u302f\u3031-\u3035\u303b\u303c\u3041-\u3096\u3099\u309a\u309d-\u309f\u30a1-\u30fa\u30fc-\u30ff\u3105-\u312d\u3131-\u318e\u31a0-\u31ba\u31f0-\u31ff\u3400-\u4db5\u4e00-\u9fcc\ua000-\ua48c\ua4d0-\ua4fd\ua500-\ua60c\ua610-\ua61f\ua62a\ua62b\ua640-\ua672\ua674-\ua67d\ua67f-\ua69d\ua69f-\ua6e5\ua6f0\ua6f1\ua717-\ua71f\ua722-\ua788\ua78b-\ua78e\ua790-\ua7ad\ua7b0\ua7b1\ua7f7-\ua827\ua840-\ua873\ua880-\ua8c4\ua8e0-\ua8f7\ua8fb\ua90a-\ua92d\ua930-\ua953\ua960-\ua97c\ua980-\ua9c0\ua9cf\ua9e0-\ua9ef\ua9fa-\ua9fe\uaa00-\uaa36\uaa40-\uaa4d\uaa60-\uaa76\uaa7a-\uaac2\uaadb-\uaadd\uaae0-\uaaef\uaaf2-\uaaf6\uab01-\uab06\uab09-\uab0e\uab11-\uab16\uab20-\uab26\uab28-\uab2e\uab30-\uab5a\uab5c-\uab5f\uab64\uab65\uabc0-\uabea\uabec\uabed\uac00-\ud7a3\ud7b0-\ud7c6\ud7cb-\ud7fb\uf870-\uf87f\uf882\uf884-\uf89f\uf8b8\uf8c1-\uf8d6\uf900-\ufa6d\ufa70-\ufad9\ufb00-\ufb06\ufb13-\ufb17\ufb1d-\ufb28\ufb2a-\ufb36\ufb38-\ufb3c\ufb3e\ufb40\ufb41\ufb43\ufb44\ufb46-\ufbb1\ufbd3-\ufd3d\ufd50-\ufd8f\ufd92-\ufdc7\ufdf0-\ufdfb\ufe00-\ufe0f\ufe20-\ufe2d\ufe70-\ufe74\ufe76-\ufefc\uff21-\uff3a\uff41-\uff5a\uff66-\uffbe\uffc2-\uffc7\uffca-\uffcf\uffd2-\uffd7\uffda-\uffdc';
  static const String _bmpNumerals =
      r'0-9\u0660-\u0669\u06f0-\u06f9\u07c0-\u07c9\u0966-\u096f\u09e6-\u09ef\u0a66-\u0a6f\u0ae6-\u0aef\u0b66-\u0b6f\u0be6-\u0bef\u0c66-\u0c6f\u0ce6-\u0cef\u0d66-\u0d6f\u0de6-\u0def\u0e50-\u0e59\u0ed0-\u0ed9\u0f20-\u0f29\u1040-\u1049\u1090-\u1099\u17e0-\u17e9\u1810-\u1819\u1946-\u194f\u19d0-\u19d9\u1a80-\u1a89\u1a90-\u1a99\u1b50-\u1b59\u1bb0-\u1bb9\u1c40-\u1c49\u1c50-\u1c59\ua620-\ua629\ua8d0-\ua8d9\ua900-\ua909\ua9d0-\ua9d9\ua9f0-\ua9f9\uaa50-\uaa59\uabf0-\uabf9\uff10-\uff19';
  static const String _cashtag = '[a-zA-Z]{1,6}(?:[._][a-zA-Z]{1,2})?';
  static const String _codePoint =
      r'(?:[^\uD800-\uDFFF]|[\uD800-\uDBFF][\uDC00-\uDFFF])';
  static const String _cyrillicLettersAndMarks = r'\u0400-\u04FF';
  static const String _directionalMarkersGroup =
      r'\u202A-\u202E\u061C\u200E\u200F\u2066\u2067\u2068\u2069';
  static const String _endHashtagMatch = '^(?:$_hashSigns|:\\/\\/)';
  static const String _endMentionMatch =
      '^(?:$_atSigns}|[$_latinAccentChars]|:\\/\\/)';
  static final RegExp _extractUrl = RegExp(
    '(' + // $1 total match
        '($_validUrlPrecedingChars)' + // $2 Preceeding character
        '(' + // $3 URL
        '(https?:\\/\\/)?' + // $4 Protocol (optional)
        '($_validDomain)' + // $5 Domain(s)
        '(?::($_validPortNumber))?' + // $6 Port number (optional)
        '(\\/$_validUrlPath*)?' + // $7 URL Path
        '(\\?$_validUrlQueryChars*$_validUrlQueryEndingChars)?' + // $8 Query String
        ')' +
        ')',
    caseSensitive: false,
  );
  static const String _hashSigns = '[#＃]';
  static const String _hashtagAlpha =
      '(?:[$_bmpLetterAndMarks]|(?=$_nonBmpCodePairs)(?:$_astralLetterAndMarks))';
  static const String _hashtagAlphaNumeric =
      '(?:[$_bmpLetterAndMarks$_bmpNumerals$_hashtagSpecialChars]|(?=$_nonBmpCodePairs)(?:$_astralLetterAndMarks|$_astralNumerals))';
  static const String _hashtagBoundary =
      '?:^|\\uFE0E|\\uFE0F|\$|(?!$_hashtagAlphaNumeric|&)$_codePoint';
  static const String _hashtagSpecialChars =
      r'_\u200c\u200d\ua67e\u05be\u05f3\u05f4\uff5e\u301c\u309b\u309c\u30a0\u30fb\u3003\u0f0b\u0f0c\xb7';
  static const String _invalidChars = '[$_invalidCharsGroup]';
  static const String _invalidCharsGroup = r'\uFFFE\uFEFF\uFFFF';
  static const String _invalidDomainChars =
      '$_punct$_spacesGroup$_invalidCharsGroup$_directionalMarkersGroup';
  static const String _invalidUrlWithoutProtocolPrecedingChars = r'[-_.\/]$';
  static const String _latinAccentChars =
      r'\xC0-\xD6\xD8-\xF6\xF8-\xFF\u0100-\u024F\u0253\u0254\u0256\u0257\u0259\u025B\u0263\u0268\u026F\u0272\u0289\u028B\u02BB\u0300-\u036F\u1E00-\u1EFF';
  static const String _nonBmpCodePairs = r'[\uD800-\uDBFF][\uDC00-\uDFFF]';
  static const String _punct = r"\!'#%&'\(\)*\+,\\\-\.\/:;<=>\?@\[\]\^_{|}~\$";
  static const String _rtlChars =
      r'[\u0600-\u06FF]|[\u0750-\u077F]|[\u0590-\u05FF]|[\uFE70-\uFEFF]';
  static const String _spaces = '[$_spacesGroup]';
  static const String _spacesGroup =
      r'\x09-\x0D\x20\x85\xA0\u1680\u180E\u2000-\u200A\u2028\u2029\u202F\u205F\u3000';
  static final RegExp _urlHasHttps =
      RegExp(r'^https:\/\/', caseSensitive: false);
  static final RegExp _validAsciiDomain = RegExp(
      '(?:(?:[\\-a-z0-9$_latinAccentChars]+)\\.)+(?:$_validGTLD|$_validCCTLD|$_validPunycode)',
      caseSensitive: false);
  static const String _validCCTLD = '(?:(?:' +
      '한국|香港|澳門|新加坡|台灣|台湾|中國|中国|გე|ລາວ|ไทย|ලංකා|ഭാരതം|ಭಾರತ|భారత్|சிங்கப்பூர்|இலங்கை|இந்தியா|ଭାରତ|' +
      'ભારત|ਭਾਰਤ|ভাৰত|ভারত|বাংলা|भारोत|भारतम्|भारत|ڀارت|پاکستان|موريتانيا|مليسيا|مصر|قطر|فلسطين|عمان|' +
      'عراق|سورية|سودان|تونس|بھارت|بارت|ایران|امارات|المغرب|السعودية|الجزائر|البحرين|الاردن|հայ|қаз|' +
      'укр|срб|рф|мон|мкд|ею|бел|бг|ευ|ελ|zw|zm|za|yt|ye|ws|wf|vu|vn|vi|vg|ve|vc|va|uz|uy|us|um|uk|' +
      'ug|ua|tz|tw|tv|tt|tr|tp|to|tn|tm|tl|tk|tj|th|tg|tf|td|tc|sz|sy|sx|sv|su|st|ss|sr|so|sn|sm|sl|' +
      'sk|sj|si|sh|sg|se|sd|sc|sb|sa|rw|ru|rs|ro|re|qa|py|pw|pt|ps|pr|pn|pm|pl|pk|ph|pg|pf|pe|pa|om|' +
      'nz|nu|nr|np|no|nl|ni|ng|nf|ne|nc|na|mz|my|mx|mw|mv|mu|mt|ms|mr|mq|mp|mo|mn|mm|ml|mk|mh|mg|mf|' +
      'me|md|mc|ma|ly|lv|lu|lt|ls|lr|lk|li|lc|lb|la|kz|ky|kw|kr|kp|kn|km|ki|kh|kg|ke|jp|jo|jm|je|it|' +
      'is|ir|iq|io|in|im|il|ie|id|hu|ht|hr|hn|hm|hk|gy|gw|gu|gt|gs|gr|gq|gp|gn|gm|gl|gi|gh|gg|gf|ge|' +
      'gd|gb|ga|fr|fo|fm|fk|fj|fi|eu|et|es|er|eh|eg|ee|ec|dz|do|dm|dk|dj|de|cz|cy|cx|cw|cv|cu|cr|co|' +
      'cn|cm|cl|ck|ci|ch|cg|cf|cd|cc|ca|bz|by|bw|bv|bt|bs|br|bq|bo|bn|bm|bl|bj|bi|bh|bg|bf|be|bd|bb|' +
      'ba|az|ax|aw|au|at|as|ar|aq|ao|an|am|al|ai|ag|af|ae|ad|ac' +
      ')(?=[^0-9a-zA-Z@+-]|\$))';
  static final RegExp _validCashtag = RegExp(
      '(^|$_spaces)(\\\$)($_cashtag)(?=\$|\\s|[$_punct])',
      caseSensitive: false);
  static const String _validDomain =
      '(?:$_validSubdomain*$_validDomainName(?:$_validGTLD|$_validCCTLD|$_validPunycode))';
  static const String _validDomainChars = '[^$_invalidDomainChars]';
  static const String _validDomainName =
      '(?:(?:$_validDomainChars(?:-|$_validDomainChars)*)?$_validDomainChars\\.)';
  static const String _validGTLD = '(?:(?:' +
      '삼성|닷컴|닷넷|香格里拉|餐厅|食品|飞利浦|電訊盈科|集团|通販|购物|谷歌|诺基亚|联通|网络|网站|网店|网址|组织机构|移动|珠宝|点看|游戏|淡马锡|机构|書籍|时尚|新闻|' +
      '政府|政务|招聘|手表|手机|我爱你|慈善|微博|广东|工行|家電|娱乐|天主教|大拿|大众汽车|在线|嘉里大酒店|嘉里|商标|商店|商城|公益|公司|八卦|健康|信息|佛山|企业|' +
      '中文网|中信|世界|ポイント|ファッション|セール|ストア|コム|グーグル|クラウド|みんな|คอม|संगठन|नेट|कॉम|همراه|موقع|موبايلي|كوم|' +
      'كاثوليك|عرب|شبكة|بيتك|بازار|العليان|ارامكو|اتصالات|ابوظبي|קום|сайт|рус|орг|онлайн|москва|ком|' +
      'католик|дети|zuerich|zone|zippo|zip|zero|zara|zappos|yun|youtube|you|yokohama|yoga|yodobashi|' +
      'yandex|yamaxun|yahoo|yachts|xyz|xxx|xperia|xin|xihuan|xfinity|xerox|xbox|wtf|wtc|wow|world|' +
      'works|work|woodside|wolterskluwer|wme|winners|wine|windows|win|williamhill|wiki|wien|whoswho|' +
      'weir|weibo|wedding|wed|website|weber|webcam|weatherchannel|weather|watches|watch|warman|' +
      'wanggou|wang|walter|walmart|wales|vuelos|voyage|voto|voting|vote|volvo|volkswagen|vodka|' +
      'vlaanderen|vivo|viva|vistaprint|vista|vision|visa|virgin|vip|vin|villas|viking|vig|video|' +
      'viajes|vet|versicherung|vermögensberatung|vermögensberater|verisign|ventures|vegas|vanguard|' +
      'vana|vacations|ups|uol|uno|university|unicom|uconnect|ubs|ubank|tvs|tushu|tunes|tui|tube|trv|' +
      'trust|travelersinsurance|travelers|travelchannel|travel|training|trading|trade|toys|toyota|' +
      'town|tours|total|toshiba|toray|top|tools|tokyo|today|tmall|tkmaxx|tjx|tjmaxx|tirol|tires|tips|' +
      'tiffany|tienda|tickets|tiaa|theatre|theater|thd|teva|tennis|temasek|telefonica|telecity|tel|' +
      'technology|tech|team|tdk|tci|taxi|tax|tattoo|tatar|tatamotors|target|taobao|talk|taipei|tab|' +
      'systems|symantec|sydney|swiss|swiftcover|swatch|suzuki|surgery|surf|support|supply|supplies|' +
      'sucks|style|study|studio|stream|store|storage|stockholm|stcgroup|stc|statoil|statefarm|' +
      'statebank|starhub|star|staples|stada|srt|srl|spreadbetting|spot|sport|spiegel|space|soy|sony|' +
      'song|solutions|solar|sohu|software|softbank|social|soccer|sncf|smile|smart|sling|skype|sky|' +
      'skin|ski|site|singles|sina|silk|shriram|showtime|show|shouji|shopping|shop|shoes|shiksha|shia|' +
      'shell|shaw|sharp|shangrila|sfr|sexy|sex|sew|seven|ses|services|sener|select|seek|security|' +
      'secure|seat|search|scot|scor|scjohnson|science|schwarz|schule|school|scholarships|schmidt|' +
      'schaeffler|scb|sca|sbs|sbi|saxo|save|sas|sarl|sapo|sap|sanofi|sandvikcoromant|sandvik|samsung|' +
      'samsclub|salon|sale|sakura|safety|safe|saarland|ryukyu|rwe|run|ruhr|rugby|rsvp|room|rogers|' +
      'rodeo|rocks|rocher|rmit|rip|rio|ril|rightathome|ricoh|richardli|rich|rexroth|reviews|review|' +
      'restaurant|rest|republican|report|repair|rentals|rent|ren|reliance|reit|reisen|reise|rehab|' +
      'redumbrella|redstone|red|recipes|realty|realtor|realestate|read|raid|radio|racing|qvc|quest|' +
      'quebec|qpon|pwc|pub|prudential|pru|protection|property|properties|promo|progressive|prof|' +
      'productions|prod|pro|prime|press|praxi|pramerica|post|porn|politie|poker|pohl|pnc|plus|' +
      'plumbing|playstation|play|place|pizza|pioneer|pink|ping|pin|pid|pictures|pictet|pics|piaget|' +
      'physio|photos|photography|photo|phone|philips|phd|pharmacy|pfizer|pet|pccw|pay|passagens|' +
      'party|parts|partners|pars|paris|panerai|panasonic|pamperedchef|page|ovh|ott|otsuka|osaka|' +
      'origins|orientexpress|organic|org|orange|oracle|open|ooo|onyourside|online|onl|ong|one|omega|' +
      'ollo|oldnavy|olayangroup|olayan|okinawa|office|off|observer|obi|nyc|ntt|nrw|nra|nowtv|nowruz|' +
      'now|norton|northwesternmutual|nokia|nissay|nissan|ninja|nikon|nike|nico|nhk|ngo|nfl|nexus|' +
      'nextdirect|next|news|newholland|new|neustar|network|netflix|netbank|net|nec|nba|navy|natura|' +
      'nationwide|name|nagoya|nadex|nab|mutuelle|mutual|museum|mtr|mtpc|mtn|msd|movistar|movie|mov|' +
      'motorcycles|moto|moscow|mortgage|mormon|mopar|montblanc|monster|money|monash|mom|moi|moe|moda|' +
      'mobily|mobile|mobi|mma|mls|mlb|mitsubishi|mit|mint|mini|mil|microsoft|miami|metlife|merckmsd|' +
      'meo|menu|men|memorial|meme|melbourne|meet|media|med|mckinsey|mcdonalds|mcd|mba|mattel|' +
      'maserati|marshalls|marriott|markets|marketing|market|map|mango|management|man|makeup|maison|' +
      'maif|madrid|macys|luxury|luxe|lupin|lundbeck|ltda|ltd|lplfinancial|lpl|love|lotto|lotte|' +
      'london|lol|loft|locus|locker|loans|loan|llp|llc|lixil|living|live|lipsy|link|linde|lincoln|' +
      'limo|limited|lilly|like|lighting|lifestyle|lifeinsurance|life|lidl|liaison|lgbt|lexus|lego|' +
      'legal|lefrak|leclerc|lease|lds|lawyer|law|latrobe|latino|lat|lasalle|lanxess|landrover|land|' +
      'lancome|lancia|lancaster|lamer|lamborghini|ladbrokes|lacaixa|kyoto|kuokgroup|kred|krd|kpn|' +
      'kpmg|kosher|komatsu|koeln|kiwi|kitchen|kindle|kinder|kim|kia|kfh|kerryproperties|' +
      'kerrylogistics|kerryhotels|kddi|kaufen|juniper|juegos|jprs|jpmorgan|joy|jot|joburg|jobs|jnj|' +
      'jmp|jll|jlc|jio|jewelry|jetzt|jeep|jcp|jcb|java|jaguar|iwc|iveco|itv|itau|istanbul|ist|' +
      'ismaili|iselect|irish|ipiranga|investments|intuit|international|intel|int|insure|insurance|' +
      'institute|ink|ing|info|infiniti|industries|inc|immobilien|immo|imdb|imamat|ikano|iinet|ifm|' +
      'ieee|icu|ice|icbc|ibm|hyundai|hyatt|hughes|htc|hsbc|how|house|hotmail|hotels|hoteles|hot|' +
      'hosting|host|hospital|horse|honeywell|honda|homesense|homes|homegoods|homedepot|holiday|' +
      'holdings|hockey|hkt|hiv|hitachi|hisamitsu|hiphop|hgtv|hermes|here|helsinki|help|healthcare|' +
      'health|hdfcbank|hdfc|hbo|haus|hangout|hamburg|hair|guru|guitars|guide|guge|gucci|guardian|' +
      'group|grocery|gripe|green|gratis|graphics|grainger|gov|got|gop|google|goog|goodyear|goodhands|' +
      'goo|golf|goldpoint|gold|godaddy|gmx|gmo|gmbh|gmail|globo|global|gle|glass|glade|giving|gives|' +
      'gifts|gift|ggee|george|genting|gent|gea|gdn|gbiz|gay|garden|gap|games|game|gallup|gallo|' +
      'gallery|gal|fyi|futbol|furniture|fund|fun|fujixerox|fujitsu|ftr|frontier|frontdoor|frogans|' +
      'frl|fresenius|free|fox|foundation|forum|forsale|forex|ford|football|foodnetwork|food|foo|fly|' +
      'flsmidth|flowers|florist|flir|flights|flickr|fitness|fit|fishing|fish|firmdale|firestone|fire|' +
      'financial|finance|final|film|fido|fidelity|fiat|ferrero|ferrari|feedback|fedex|fast|fashion|' +
      'farmers|farm|fans|fan|family|faith|fairwinds|fail|fage|extraspace|express|exposed|expert|' +
      'exchange|everbank|events|eus|eurovision|etisalat|esurance|estate|esq|erni|ericsson|equipment|' +
      'epson|epost|enterprises|engineering|engineer|energy|emerck|email|education|edu|edeka|eco|eat|' +
      'earth|dvr|dvag|durban|dupont|duns|dunlop|duck|dubai|dtv|drive|download|dot|doosan|domains|' +
      'doha|dog|dodge|doctor|docs|dnp|diy|dish|discover|discount|directory|direct|digital|diet|' +
      'diamonds|dhl|dev|design|desi|dentist|dental|democrat|delta|deloitte|dell|delivery|degree|' +
      'deals|dealer|deal|dds|dclk|day|datsun|dating|date|data|dance|dad|dabur|cyou|cymru|cuisinella|' +
      'csc|cruises|cruise|crs|crown|cricket|creditunion|creditcard|credit|cpa|courses|coupons|coupon|' +
      'country|corsica|coop|cool|cookingchannel|cooking|contractors|contact|consulting|construction|' +
      'condos|comsec|computer|compare|company|community|commbank|comcast|com|cologne|college|coffee|' +
      'codes|coach|clubmed|club|cloud|clothing|clinique|clinic|click|cleaning|claims|cityeats|city|' +
      'citic|citi|citadel|cisco|circle|cipriani|church|chrysler|chrome|christmas|chloe|chintai|cheap|' +
      'chat|chase|charity|channel|chanel|cfd|cfa|cern|ceo|center|ceb|cbs|cbre|cbn|cba|catholic|' +
      'catering|cat|casino|cash|caseih|case|casa|cartier|cars|careers|career|care|cards|caravan|car|' +
      'capitalone|capital|capetown|canon|cancerresearch|camp|camera|cam|calvinklein|call|cal|cafe|' +
      'cab|bzh|buzz|buy|business|builders|build|bugatti|budapest|brussels|brother|broker|broadway|' +
      'bridgestone|bradesco|box|boutique|bot|boston|bostik|bosch|boots|booking|book|boo|bond|bom|' +
      'bofa|boehringer|boats|bnpparibas|bnl|bmw|bms|blue|bloomberg|blog|blockbuster|blanco|' +
      'blackfriday|black|biz|bio|bingo|bing|bike|bid|bible|bharti|bet|bestbuy|best|berlin|bentley|' +
      'beer|beauty|beats|bcn|bcg|bbva|bbt|bbc|bayern|bauhaus|basketball|baseball|bargains|barefoot|' +
      'barclays|barclaycard|barcelona|bar|bank|band|bananarepublic|banamex|baidu|baby|azure|axa|aws|' +
      'avianca|autos|auto|author|auspost|audio|audible|audi|auction|attorney|athleta|associates|asia|' +
      'asda|arte|art|arpa|army|archi|aramco|arab|aquarelle|apple|app|apartments|aol|anz|anquan|' +
      'android|analytics|amsterdam|amica|amfam|amex|americanfamily|americanexpress|alstom|alsace|' +
      'ally|allstate|allfinanz|alipay|alibaba|alfaromeo|akdn|airtel|airforce|airbus|aigo|aig|agency|' +
      'agakhan|africa|afl|afamilycompany|aetna|aero|aeg|adult|ads|adac|actor|active|aco|accountants|' +
      'accountant|accenture|academy|abudhabi|abogado|able|abc|abbvie|abbott|abb|abarth|aarp|aaa|' +
      'onion' +
      ')(?=[^0-9a-zA-Z@+-]|\$))';
  static const String _validGeneralUrlPathChars =
      "[a-z${_cyrillicLettersAndMarks}0-9!\\*';:=\\+,\\.\\\$\\/%#\\[\\]\\-\\u2013_~@\\|&$_latinAccentChars]";

  /// Regex pattern for a valid hashtag.
  static final RegExp validHashtag = RegExp(
      '($_hashtagBoundary)($_hashSigns)(?!\\uFE0F|\\u20E3)($_hashtagAlphaNumeric*$_hashtagAlpha$_hashtagAlphaNumeric*)',
      caseSensitive: false);
  static final RegExp _validMention =
      RegExp('($_validMentionPrecedingChars)' + // $1: Preceding character
          '($_atSigns)' + // $2: At mark
          '([a-zA-Z0-9_]{1,20})'); // $3: Screen name'
  static final RegExp _validMentionOrList =
      RegExp('($_validMentionPrecedingChars)' + // $1: Preceding character
          '($_atSigns)' + // $2: At mark
          '([a-zA-Z0-9_]{1,20})' + // $3: Screen name'
          '(/[a-zA-Z][a-zA-Z0-9_-]{0,24})?'); // $4: List (optional)
  static const String _validMentionPrecedingChars =
      r'(?:^|[^a-zA-Z0-9_!#$%&*@＠]|(?:^|[^a-zA-Z0-9_+~.-])(?:rt|RT|rT|Rt):?)';
  static const String _validPortNumber = '[0-9]+';
  static const String _validPunycode = r'(?:xn--[\-0-9a-z]+)';
  static const String _validReply =
      '^(?:$_spaces)*$_atSigns([a-zA-Z0-9_]{1,20})';
  static const String _validSubdomain =
      '(?:(?:$_validDomainChars(?:[_-]|$_validDomainChars)*)?$_validDomainChars\\.)';
  static final RegExp _validTcoUrl = RegExp(
      '^https?:\\/\\/t\\.co\\/([a-z0-9]+)(?:\\?#{validUrlQueryChars}*#{validUrlQueryEndingChars})?',
      caseSensitive: false);
  static const String _validUrlBalancedParens = r'\(' +
      '(?:' +
      '#{validGeneralUrlPathChars}+' +
      '|' +
      // allow one nested level of balanced parentheses
      '(?:' +
      '#{validGeneralUrlPathChars}*' +
      '\\(' +
      '#{validGeneralUrlPathChars}+' +
      '\\)' +
      '#{validGeneralUrlPathChars}*' +
      ')' +
      ')' +
      '\\)';
  static const String _validUrlPath = '(?:' +
      '(?:' +
      '$_validGeneralUrlPathChars*' +
      '(?:$_validUrlBalancedParens$_validGeneralUrlPathChars*)*' +
      _validUrlPathEndingChars +
      ')|(?:@$_validGeneralUrlPathChars+/)' +
      ')';
  static const String _validUrlPathEndingChars =
      '[\\+\\-a-z${_cyrillicLettersAndMarks}0-9=_#\\/$_latinAccentChars]|(?:$_validUrlBalancedParens)';
  static const String _validUrlPrecedingChars =
      '(?:[^A-Za-z0-9@＠\$#＃$_invalidCharsGroup]|[$_directionalMarkersGroup]|^)';
  static const String _validUrlQueryChars =
      r"[a-z0-9!?\*'@\(\);:&=\+\$\/%#\[\]\-_\.,~|]";
  static const String _validUrlQueryEndingChars = r'[a-z0-9\-_&=#\/]';
  static const String _validateUrlAuthority = '(?:($_validateUrlUserinfo)@)?' +
      // $2 host
      '($_validateUrlHost)' +
      // $3 port
      '(?::($_validateUrlPort))?';
  static const String _validateUrlDecOctet =
      '(?:[0-9]|(?:[1-9][0-9])|(?:1[0-9]{2})|(?:2[0-4][0-9])|(?:25[0-5]))';
  static const String _validateUrlDomain =
      '(?:(?:$_validateUrlSubDomainSegment\\.)*(?:$_validateUrlDomainSegment\\.)$_validateUrlDomainTld)';
  static const String _validateUrlDomainSegment =
      r'(?:[a-z0-9](?:[a-z0-9\-]*[a-z0-9])?)';
  static const String _validateUrlDomainTld =
      r'(?:[a-z](?:[a-z0-9\-]*[a-z0-9])?)';
  static const String _validateUrlFragment = '($_validateUrlPchar|\\/|\\?)*';
  static const String _validateUrlHost =
      '(?:$_validateUrlIp|$_validateUrlDomain)';
  static const String _validateUrlIp =
      '(?:$_validateUrlIpv4|$_validateUrlIpv6)';
  static const String _validateUrlIpv4 =
      '(?:$_validateUrlDecOctet(?:\\.$_validateUrlDecOctet){3})';
  static const String _validateUrlIpv6 = r'(?:\[[a-f0-9:\.]+\])';
  static const String _validateUrlPath = '(\\/$_validateUrlPchar*)*';
  static const String _validateUrlPchar =
      '(?:$_validateUrlUnreserved|$_validateUrlPctEncoded|$_validateUrlSubDelims|[:|@])';
  static const String _validateUrlPctEncoded = '(?:%[0-9a-f]{2})';
  static const String _validateUrlPort = '[0-9]{1,5}';
  static const String _validateUrlQuery = '($_validateUrlPchar|\\/|\\?)*';
  static const String _validateUrlScheme = r'(?:[a-z][a-z0-9+\-.]*)';
  static const String _validateUrlSubDelims = r"[!$&'()*+,;=]";
  static const String _validateUrlSubDomainSegment =
      r'(?:[a-z0-9](?:[a-z0-9_\-]*[a-z0-9])?)';
  static const String _validateUrlUnencoded = '^' + // Full URL
      '(?:' +
      '([^:/?#]+):\\/\\/' + // $1 Scheme
      ')?' +
      '([^/?#]*)' + // $2 Authority
      '([^?#]*)' + // $3 Path
      '(?:' +
      '\\?([^#]*)' + // $4 Query
      ')?' +
      '(?:' +
      '#(.*)' + // $5 Fragment
      ')?\$';
  static const String _validateUrlUnicodeAuthority =
      // $1 userinfo
      '(?:($_validateUrlUserinfo)@)?' +
          // $2 host
          '($_validateUrlUnicodeHost)' +
          // $3 port
          '(?::($_validateUrlPort))?';
  static const String _validateUrlUnicodeDomain =
      '(?:(?:$_validateUrlUnicodeSubDomainSegment\\.)*(?:$_validateUrlUnicodeDomainSegment\\.)$_validateUrlUnicodeDomainTld)';
  static const String _validateUrlUnicodeDomainSegment =
      r'(?:(?:[a-z0-9]|[^\u0000-\u007f])(?:(?:[a-z0-9\-]|[^\u0000-\u007f])*(?:[a-z0-9]|[^\u0000-\u007f]))?)';
  static const String _validateUrlUnicodeDomainTld =
      r'(?:(?:[a-z]|[^\u0000-\u007f])(?:(?:[a-z0-9\-]|[^\u0000-\u007f])*(?:[a-z0-9]|[^\u0000-\u007f]))?)';
  static const String _validateUrlUnicodeHost =
      '(?:$_validateUrlIp|$_validateUrlUnicodeDomain)';
  static const String _validateUrlUnicodeSubDomainSegment =
      r'(?:(?:[a-z0-9]|[^\u0000-\u007f])(?:(?:[a-z0-9_\-]|[^\u0000-\u007f])*(?:[a-z0-9]|[^\u0000-\u007f]))?)';
  static const String _validateUrlUnreserved = r'[a-z\u0400-\u04FF0-9\-._~]';
  static const String _validateUrlUserinfo =
      '(?:$_validateUrlUnreserved|$_validateUrlPctEncoded|$_validateUrlSubDelims|:)*';
}

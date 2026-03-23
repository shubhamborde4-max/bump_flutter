import 'package:bump/data/models/user_model.dart';
import 'package:bump/data/models/event_model.dart';
import 'package:bump/data/models/prospect_model.dart';
import 'package:bump/data/models/nudge_model.dart';
import 'package:bump/data/models/template_model.dart';

class MockData {
  MockData._();

  // ── User ──────────────────────────────────────────────────────────────────

  static const User user = User(
    id: 'user-1',
    username: 'harshank',
    firstName: 'Harshank',
    lastName: 'Patel',
    email: 'harshank@techventures.in',
    phone: '+91 98765 43210',
    company: 'TechVentures India',
    title: 'CEO',
    linkedIn: 'https://linkedin.com/in/harshankpatel',
    website: 'https://techventures.in',
    bio:
        'Building the future of business networking. Passionate about connecting people through technology.',
    cardStyle: CardStyle.modern,
    totalBumps: 47,
    totalNudges: 23,
    conversionRate: 68.5,
  );

  // ── Events ────────────────────────────────────────────────────────────────

  static final List<Event> events = [
    Event(
      id: 'event-1',
      name: 'TechCrunch Disrupt Mumbai',
      date: DateTime(2026, 3, 10, 9, 0),
      endDate: DateTime(2026, 3, 12, 18, 0),
      location: 'Jio World Convention Centre, Mumbai',
      totalProspects: 12,
      nudgesSent: 6,
      isActive: true,
    ),
    Event(
      id: 'event-2',
      name: 'SaaS Connect Bangalore',
      date: DateTime(2026, 2, 20, 9, 0),
      endDate: DateTime(2026, 2, 21, 18, 0),
      location: 'Bangalore International Exhibition Centre',
      totalProspects: 5,
      nudgesSent: 2,
      isActive: false,
    ),
    Event(
      id: 'event-3',
      name: 'Web Summit Goa',
      date: DateTime(2026, 4, 15, 9, 0),
      endDate: DateTime(2026, 4, 17, 18, 0),
      location: 'Goa Convention Centre',
      totalProspects: 3,
      nudgesSent: 0,
      isActive: false,
    ),
  ];

  // ── Prospects ─────────────────────────────────────────────────────────────

  static final List<Prospect> prospects = [
    // ── TechCrunch Disrupt Mumbai (event-1) ──
    Prospect(
      id: 'p-1',
      eventId: 'event-1',
      firstName: 'Deepinder',
      lastName: 'Goyal',
      email: 'deepinder@zomato.com',
      phone: '+91 99876 54321',
      company: 'Zomato',
      title: 'CEO',
      notes:
          'Interested in enterprise API pricing. Wants to integrate Bump with Zomato for Business.',
      status: ProspectStatus.interested,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 10, 14, 32),
      linkedIn: 'https://linkedin.com/in/deepindergoyal',
      tags: ['hot-lead'],
    ),
    Prospect(
      id: 'p-2',
      eventId: 'event-1',
      firstName: 'Harshil',
      lastName: 'Mathur',
      email: 'harshil@razorpay.com',
      phone: '+91 98765 12345',
      company: 'Razorpay',
      title: 'Co-Founder & CEO',
      notes:
          'Looking for POS integrations. Mentioned a potential partnership opportunity.',
      status: ProspectStatus.contacted,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 10, 11, 15),
      linkedIn: 'https://linkedin.com/in/harshilmathur',
      tags: ['partner'],
    ),
    Prospect(
      id: 'p-3',
      eventId: 'event-1',
      firstName: 'Girish',
      lastName: 'Mathrubootham',
      email: 'girish@freshworks.com',
      phone: '+91 99887 76543',
      company: 'Freshworks',
      title: 'Founder & Chairman',
      notes:
          'Wants demo for team of 50. Very interested in CRM integration features.',
      status: ProspectStatus.converted,
      exchangeMethod: ExchangeMethod.qr,
      exchangeTime: DateTime(2026, 3, 11, 9, 45),
      tags: ['hot-lead'],
    ),
    Prospect(
      id: 'p-4',
      eventId: 'event-1',
      firstName: 'Nithin',
      lastName: 'Kamath',
      email: 'nithin@zerodha.com',
      phone: '+91 98765 98765',
      company: 'Zerodha',
      title: 'Founder & CEO',
      notes:
          'Interested in fintech networking features. Has a large team that attends events.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 11, 14, 20),
    ),
    Prospect(
      id: 'p-5',
      eventId: 'event-1',
      firstName: 'Sriharsha',
      lastName: 'Majety',
      email: 'sriharsha@swiggy.com',
      phone: '+91 99876 11111',
      company: 'Swiggy',
      title: 'Co-Founder & CEO',
      notes:
          'Looking for enterprise solutions. Wants to connect their BD team.',
      status: ProspectStatus.contacted,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 10, 16, 50),
      tags: ['follow-up'],
    ),
    Prospect(
      id: 'p-6',
      eventId: 'event-1',
      firstName: 'Ivan',
      lastName: 'Zhao',
      email: 'ivan@notion.so',
      phone: '+1 415 555 0101',
      company: 'Notion',
      title: 'Co-Founder & CEO',
      notes:
          'Discussed potential Notion integration for contact management.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 12, 10, 30),
      linkedIn: 'https://linkedin.com/in/ivanzhao',
    ),
    Prospect(
      id: 'p-7',
      eventId: 'event-1',
      firstName: 'Dylan',
      lastName: 'Field',
      email: 'dylan@figma.com',
      phone: '+1 415 555 0202',
      company: 'Figma',
      title: 'Co-Founder & CEO',
      notes:
          'Interested in design collaboration features. Loves the UI.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.qr,
      exchangeTime: DateTime(2026, 3, 12, 11, 15),
    ),
    Prospect(
      id: 'p-8',
      eventId: 'event-1',
      firstName: 'Patrick',
      lastName: 'Collison',
      email: 'patrick@stripe.com',
      phone: '+1 415 555 0303',
      company: 'Stripe',
      title: 'Co-Founder & CEO',
      notes:
          'Wants to explore payment integration for premium Bump features.',
      status: ProspectStatus.interested,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 10, 15, 0),
      linkedIn: 'https://linkedin.com/in/patrickcollison',
      tags: ['hot-lead', 'partner'],
    ),
    Prospect(
      id: 'p-9',
      eventId: 'event-1',
      firstName: 'Kunal',
      lastName: 'Shah',
      email: 'kunal@cred.club',
      phone: '+91 98765 22222',
      company: 'CRED',
      title: 'Founder',
      notes: 'Potential investor. Very bullish on the concept.',
      status: ProspectStatus.converted,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 11, 13, 0),
      tags: ['hot-lead'],
    ),
    Prospect(
      id: 'p-10',
      eventId: 'event-1',
      firstName: 'Bhavish',
      lastName: 'Aggarwal',
      email: 'bhavish@olacabs.com',
      phone: '+91 98765 33333',
      company: 'Ola',
      title: 'Founder & CEO',
      notes: 'Discussed corporate event networking use case.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 12, 9, 0),
    ),
    Prospect(
      id: 'p-11',
      eventId: 'event-1',
      firstName: 'Vijay',
      lastName: 'Shekhar',
      email: 'vijay@paytm.com',
      phone: '+91 98765 44444',
      company: 'Paytm',
      title: 'Founder & CEO',
      notes:
          'Discussed digital payments integration for premium features.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 3, 11, 10, 0),
    ),
    Prospect(
      id: 'p-12',
      eventId: 'event-1',
      firstName: 'Naveen',
      lastName: 'Tewari',
      email: 'naveen@inmobi.com',
      phone: '+91 98765 55555',
      company: 'InMobi',
      title: 'Founder & CEO',
      notes:
          'AdTech perspective on event networking. Potential ad partnership.',
      status: ProspectStatus.contacted,
      exchangeMethod: ExchangeMethod.qr,
      exchangeTime: DateTime(2026, 3, 10, 17, 30),
      tags: ['partner'],
    ),

    // ── SaaS Connect Bangalore (event-2) ──
    Prospect(
      id: 'p-13',
      eventId: 'event-2',
      firstName: 'Ankit',
      lastName: 'Jain',
      email: 'ankit@infinitus.ai',
      phone: '+91 99887 44444',
      company: 'Infinitus Systems',
      title: 'CEO',
      notes:
          'AI-powered healthcare automation. Interested in API integration.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 2, 20, 9, 30),
    ),
    Prospect(
      id: 'p-14',
      eventId: 'event-2',
      firstName: 'Varun',
      lastName: 'Alagh',
      email: 'varun@mamaearth.in',
      phone: '+91 99887 55555',
      company: 'Mamaearth',
      title: 'Co-Founder',
      notes: 'D2C brand looking for B2B networking solutions.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 2, 20, 10, 15),
    ),
    Prospect(
      id: 'p-15',
      eventId: 'event-2',
      firstName: 'Ashneer',
      lastName: 'Grover',
      email: 'ashneer@thirduni.com',
      phone: '+91 99887 66666',
      company: 'Third Unicorn',
      title: 'Founder',
      notes: 'Angel investor. Wants to discuss seed round.',
      status: ProspectStatus.contacted,
      exchangeMethod: ExchangeMethod.qr,
      exchangeTime: DateTime(2026, 2, 20, 11, 0),
      tags: ['hot-lead'],
    ),
    Prospect(
      id: 'p-16',
      eventId: 'event-2',
      firstName: 'Nandan',
      lastName: 'Reddy',
      email: 'nandan@swiggy.com',
      phone: '+91 99887 77777',
      company: 'Swiggy',
      title: 'Co-Founder',
      notes: 'Looking at Bump for Swiggy Dineout events.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 2, 20, 11, 45),
    ),
    Prospect(
      id: 'p-17',
      eventId: 'event-2',
      firstName: 'Falguni',
      lastName: 'Nayar',
      email: 'falguni@nykaa.com',
      phone: '+91 99887 88888',
      company: 'Nykaa',
      title: 'Founder & CEO',
      notes: 'Interested in beauty industry networking events.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 2, 20, 12, 30),
    ),

    // ── Web Summit Goa (event-3) ──
    Prospect(
      id: 'p-18',
      eventId: 'event-3',
      firstName: 'Ritesh',
      lastName: 'Agarwal',
      email: 'ritesh@oyorooms.com',
      phone: '+91 99887 99999',
      company: 'OYO',
      title: 'Founder & CEO',
      notes:
          'Wants Bump at OYO partner meets. Large scale deployment interest.',
      status: ProspectStatus.contacted,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 4, 15, 13, 15),
      tags: ['partner'],
    ),
    Prospect(
      id: 'p-19',
      eventId: 'event-3',
      firstName: 'Byju',
      lastName: 'Raveendran',
      email: 'byju@byjus.com',
      phone: '+91 98765 66666',
      company: "BYJU'S",
      title: 'Founder & CEO',
      notes: 'EdTech networking use case. Large event presence.',
      status: ProspectStatus.archived,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 4, 15, 14, 0),
    ),
    Prospect(
      id: 'p-20',
      eventId: 'event-3',
      firstName: 'Priya',
      lastName: 'Sharma',
      email: 'priya@meesho.com',
      phone: '+91 99876 22222',
      company: 'Meesho',
      title: 'VP Engineering',
      notes: 'Technical evaluation for Meesho seller meetups.',
      status: ProspectStatus.newProspect,
      exchangeMethod: ExchangeMethod.bump,
      exchangeTime: DateTime(2026, 4, 15, 14, 30),
      tags: ['follow-up'],
    ),
  ];

  // ── Nudge History ─────────────────────────────────────────────────────────

  static final List<Nudge> nudgeHistory = [
    Nudge(
      id: 'n-1',
      prospectId: 'p-1',
      type: NudgeType.whatsapp,
      message:
          'Hi Deepinder! Great meeting you at TechCrunch Disrupt. Would love to discuss the API integration further. Free for a call this week?',
      sentAt: DateTime(2026, 3, 10, 18, 0),
      status: NudgeStatus.read,
    ),
    Nudge(
      id: 'n-2',
      prospectId: 'p-2',
      type: NudgeType.whatsapp,
      message:
          'Hey Harshil, loved our conversation about POS integrations. Let me send over a detailed proposal. When works best for your team?',
      sentAt: DateTime(2026, 3, 11, 9, 0),
      status: NudgeStatus.delivered,
    ),
    Nudge(
      id: 'n-3',
      prospectId: 'p-3',
      type: NudgeType.email,
      message:
          'Following up on the demo request for Freshworks. I have prepared a custom walkthrough for a team of 50.',
      sentAt: DateTime(2026, 3, 11, 14, 0),
      status: NudgeStatus.sent,
    ),
    Nudge(
      id: 'n-4',
      prospectId: 'p-5',
      type: NudgeType.whatsapp,
      message:
          'Hi Sriharsha! Great connecting at Disrupt. I would love to set up a demo with your BD team. When works for you?',
      sentAt: DateTime(2026, 3, 11, 10, 30),
      status: NudgeStatus.read,
    ),
    Nudge(
      id: 'n-5',
      prospectId: 'p-8',
      type: NudgeType.whatsapp,
      message:
          'Patrick, great meeting you! The payment integration idea sounds fantastic. Let us schedule a deep-dive next week?',
      sentAt: DateTime(2026, 3, 10, 20, 0),
      status: NudgeStatus.delivered,
    ),
    Nudge(
      id: 'n-6',
      prospectId: 'p-9',
      type: NudgeType.whatsapp,
      message:
          'Kunal! Thanks for the incredible feedback on Bump. Would love to discuss the investment opportunity further.',
      sentAt: DateTime(2026, 3, 12, 9, 0),
      status: NudgeStatus.read,
    ),
    Nudge(
      id: 'n-7',
      prospectId: 'p-15',
      type: NudgeType.whatsapp,
      message:
          'Hi Ashneer, great to connect at SaaS Connect! Would love to chat about the seed round opportunity.',
      sentAt: DateTime(2026, 2, 20, 12, 0),
      status: NudgeStatus.replied,
    ),
    Nudge(
      id: 'n-8',
      prospectId: 'p-18',
      type: NudgeType.sms,
      message:
          'Ritesh, exciting to hear about OYO partner meets! Let me put together a proposal for large-scale deployment.',
      sentAt: DateTime(2026, 4, 15, 14, 0),
      status: NudgeStatus.sent,
    ),
  ];

  // ── Templates ─────────────────────────────────────────────────────────────

  static const List<Template> templates = [
    Template(
      id: 'tmpl-1',
      name: 'Quick Follow-up',
      message:
          'Hi {{firstName}}, great meeting you at {{eventName}}! I really enjoyed our conversation about {{topic}}. Would love to continue the discussion - are you free for a quick call this week?',
      category: TemplateCategory.followUp,
    ),
    Template(
      id: 'tmpl-2',
      name: 'Meeting Request',
      message:
          'Hi {{firstName}}, it was wonderful connecting at {{eventName}}. I would love to schedule a meeting to explore how we can work together. Would {{suggestedTime}} work for you?',
      category: TemplateCategory.meeting,
    ),
    Template(
      id: 'tmpl-3',
      name: 'Introduction',
      message:
          'Hi {{firstName}}, I am {{userName}} from {{userCompany}}. We met at {{eventName}} and I was really impressed by what {{company}} is doing. I would love to explore potential synergies between our teams.',
      category: TemplateCategory.intro,
    ),
  ];

  // ── Avatar gradient pairs ─────────────────────────────────────────────────

  static const List<List<String>> avatarGradientHexPairs = [
    ['#6C5CE7', '#00D2FF'],
    ['#FF6B6B', '#FFE66D'],
    ['#00D2FF', '#00B894'],
    ['#FD79A8', '#FDCB6E'],
    ['#A29BFE', '#74B9FF'],
    ['#55A3F8', '#7C4DFF'],
    ['#FF9100', '#FF6D00'],
    ['#00C853', '#69F0AE'],
  ];
}

require 'httparty'
require 'httparty_with_cookies'

module URI
  def self.unescape(p)
    CGI.unescape(p)
  end
end

class TollChecker
  include HTTParty_with_cookies

  attr_reader :invoice_line

  # BASE_URL = 'https://ct.rmatoll.com/Violator/ViewInvoices'
  BASE_URL = 'https://ct.rmatoll.com/Home/PayViolation'
  HOME_URL = 'https://ct.rmatoll.com/Home/Login'

  PARAMS = {
    IsVerified: 'False',
    EntryTripDateTime: '01/01/0001 00:00:00',
    TollAmount: 0,
    FeeAmount: 0,
    BalanceDue: 0,
    ViolatorId: 0,
    ProblemId: 0,
    TotalCount: 0,
    TotalCountSWC: 0,
    DefaultPageSize: 0,
    DefaultPageSizeSWC: 0,
    IsEMIExists: 'False',
    IsDateRequired: 'False',
    PreviousPage: 0,
    PayFor: 'PLATE',
    IstremPayment: 'False',
    AmountToPayForEMI: 0,
    EMIHeaderId: 0,
    InvoiceID: 0,
    IsHold: 'False',
    ActualEMIAmount: 0,
    EMIDueAmount: 0,
    IsPayForCard: 'False',
    IsPayForPlateNumber: 'False',
    IsPayForReferenceNumber: 'False',
    CollectionAmount: 0,
    CollectionAmountSWC: 0,
    AgencyCode: 'CTRMA',
    OutstandingAmount: 0,
    AmountToPay: 0,
    InvoiceHoldAmount: 0,
    IsHV: 'False',
    TotalAmount: 0,
    isclicked: 0,
    InvoiceOutstandingAmount: 0,
    VehicleId: 0,
    NextTermDueAmount: 0,
    isPenniCreditPaging: 'False',
    isSWCPaging: 'False',
    PageNumberSWC: 0,
    SortDirSWC: 0,
    PageSizeSWC: 0,
    PageNumberPennCredit: 0,
    SortDirPennCredit: 0,
    PageSizePennCredit: 0,
    PennCreditOutstandingAmount: 0,
    SWCOutstandingAmount: 0,
    TotalInvoiceAmount: 0,
    DocumentExistsForInvoices: 'False',
    HidePaymentPlanButton: 'False',
    ParentViolatorIdPaymentPlan: 0,
    IsVoidAccount: 'False',
    PageNumber: 1,
    PageSize: 10,
    SortDir: 0
  }
  DATE_FORMAT = '%m/%d/%Y'

  def initialize(license:, sdate: Date.today, edate: Date.today - 7)
    @license = license
    @edate = edate
    @sdate = sdate
  end

  def csrf_token
    @csrf_line  ||= csrfr.response.body.lines.find { |l| l.include?('__RequestVerificationToken') }
    @csrf_token ||= @csrf_line.match(/value="(?<csrf>.*)"/)[:csrf]
  end

  def csrfr
    @csrfr ||= get(
      HOME_URL
    )
  end

  def response
    @response ||= post(
      BASE_URL,
      body: {
        '__RequestVerificationToken' => csrf_token,
        'objViolation.PayFor' => 'PLATE',
        'objViolation.InvoiceNo' => '',
        'objViolation.VehicleNo' => '',
        'objViolation.VehicleNumber' => @license,
        'objViolation.StartDate' => @sdate.strftime(DATE_FORMAT),
        'objViolation.EndDate' => @edate.strftime(DATE_FORMAT)
      }
    )
  end

  def new_bill?
    @invoice_line = response.body.lines.find { |line| line.include?('var vInvoices') }

    !@invoice_line.nil? && @invoice_line.size > 60
  end
end

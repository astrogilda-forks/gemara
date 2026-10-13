// SPDX-License-Identifier: Apache-2.0

// Schema lifecycle: experimental | stable | deprecated
@gemara(status="stable")
package gemara

@go(gemara)

// EvaluationLog contains the results of evaluating a set of Layer 2 controls.
#EvaluationLog: {
	#Log
	metadata: type: "EvaluationLog"
	// result is the aggregate outcome across all evaluations in this log
	result: #Result
	evaluations: [#ControlEvaluation, ...#ControlEvaluation] @go(Evaluations,type=[]*ControlEvaluation)

	// Evidence held elsewhere that omits digest relies on its source url to fix the
	// bytes, which an oci url does only when pinned by digest (see #EvidenceMapping.digest).
	if evaluations != _|_ && metadata."mapping-references" != _|_ {
		_ociURLs: {for m in metadata."mapping-references" if m.url != _|_ if m.url =~ "^oci://" {(m.id): m.url}}
		for e in evaluations
		for a in e."assessment-logs"
		if a.evidence != _|_
		for item in a.evidence
		if item.payload == _|_ && item.source != _|_ && item.source.digest == _|_
		if _ociURLs[item.source."reference-id"] != _|_
		if (_ociURLs[item.source."reference-id"] & _contentAddressedOCI) == _|_ {
			_digestBasis: (item.id): error("evidence \(item.id) omits digest and its source \(item.source."reference-id") is an oci url not pinned by digest: pin the url as oci://<name>@<algorithm>:<encoded> or give digest")
		}
	}
}

// ControlEvaluation contains the results of evaluating a single Layer 5 control.
#ControlEvaluation: {
	name:    string
	result:  #Result
	message: string
	control: #EntryMapping
	"assessment-logs": [#AssessmentLog, ...#AssessmentLog] @gemara(projectable=false) @go(AssessmentLogs,type=[]*AssessmentLog)
	// Enforce that control reference and the assessments' references match
	// This formulation uses the control's reference if the assessment doesn't include a reference
	"assessment-logs": [...{
		requirement: "reference-id": (control."reference-id")
	}]
	// Require start timestamp on assessments that actually executed
	"assessment-logs": [#_AssessmentLogStrict, ...#_AssessmentLogStrict]
}

// _AssessmentLogStrict layers the "start required unless unexecuted" rule on top of #AssessmentLog
#_AssessmentLogStrict: {
	@go(-)
} & #AssessmentLog & {
	result: #Result
	if result != "Not Run" && result != "Unknown" && result != "Not Applicable" {
		start: #Datetime
	}
}

// AssessmentLog contains the results of executing a single assessment procedure for a control requirement.
#AssessmentLog: {
	// Requirement should map to the assessment requirement for this assessment.
	requirement: #EntryMapping
	// Plan maps to the policy assessment plan being executed.
	plan?: #EntryMapping @go(Plan,optional=nillable)
	// Description provides a summary of the assessment procedure.
	description: string
	// Result is the overall outcome of the assessment procedure, matching the result of the last step that was run.
	result: #Result
	// Message provides additional context about the assessment result.
	message: string
	// Applicability is elevated from the Layer 2 Assessment Requirement to aid in execution and reporting.
	applicability: [string, ...string] @go(Applicability,type=[]string)
	// Steps are sequential actions taken as part of the assessment, which may halt the assessment if a failure occurs.
	steps: [#AssessmentStep, ...#AssessmentStep]
	// Steps-executed is the number of steps that were executed as part of the assessment.
	"steps-executed"?: int @go(StepsExecuted)
	// Start is the timestamp when the assessment began.
	// Assessments that never executed have no start time to record.
	start?: #Datetime

	// End is the timestamp when the assessment concluded.
	end?: #Datetime
	// Recommendation provides guidance on how to address a failed assessment.
	recommendation?: string
	// ConfidenceLevel indicates the evaluator's confidence level in this specific assessment result.
	"confidence-level"?: #ConfidenceLevel @go(ConfidenceLevel)
	// Evidence records the raw data cited to support this assessment's opinion.
	evidence?: [#Evidence, ...#Evidence] @go(Evidence)
	evidence?: [#_EvidenceStrict, ...#_EvidenceStrict]
}

#AssessmentStep: string @go(-)

#Result: "Not Run" | "Passed" | "Failed" | "Needs Review" | "Not Applicable" | "Unknown" @go(-)

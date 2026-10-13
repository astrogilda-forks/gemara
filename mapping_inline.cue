// SPDX-License-Identifier: Apache-2.0

// Schema lifecycle: experimental | stable | deprecated
@gemara(status="stable")

package gemara

// MappingReference represents a reference to an external document with full metadata.
#MappingReference: {
	// id identifies this mapping reference within the artifact and, when url
	// is absent, the referenced artifact's metadata.id.
	id: string

	// title describes the purpose of this mapping reference at a glance
	title: string

	// version is the version identifier of the artifact being mapped to
	version: string

	// description is prose regarding the artifact's purpose or content
	description?: string

	// url is the path where the artifact may be retrieved; preferably responds with Gemara-compatible YAML/JSON.
	// Any URI scheme is accepted (e.g. https, file, oci, s3, arn) so evidence can be
	// addressed wherever it actually lives.
	url?: =~"^[a-zA-Z][a-zA-Z0-9+.-]*:[^\\s]+$"
}

// ArtifactMapping represents a mapping to an external artifact or artifact entry
#ArtifactMapping: {
	// reference-id identifies an element from a MappingReference in the artifact's metadata
	"reference-id": string @go(ReferenceId)

	// remarks is prose regarding the mapped artifact or the mapping relationship
	remarks?: string
}

// MultiEntryMapping represents a mapping to an external reference with one or more entries.
#MultiEntryMapping: {
	// top-level reference to the MappingReference entry
	#ArtifactMapping

	// entries is a list of mapping entries
	entries: [#ArtifactMapping, ...#ArtifactMapping] @go(Entries)
}

// EntryMapping represents how a specific entry maps to a MappingReference.
#EntryMapping: {
	// reference-id is the id for a MappingReference entry in the artifact's metadata
	"reference-id": string @go(ReferenceId)

	// entry-id is the identifier being mapped to in the referenced artifact
	"entry-id": string @go(EntryId)

	// remarks is prose describing the mapping relationship
	remarks?: string
}

// EvidenceMapping identifies the source from which evidence was collected.
// reference-id names the MappingReference; coordinate or entry-id gives
// specificity within it; digest pins the resolved evidence content at collection
// time, not the resource identity named by the MappingReference url.
#EvidenceMapping: {
	// reference-id ties this evidence to a mapping-reference in the artifact's metadata
	"reference-id": string @go(ReferenceId)

	// coordinate is the precise location within the stream identified by reference-id
	// (e.g. an API path, file path, or JSON path expression). May be combined with
	// entry-id to identify a sub-location within that entry's output.
	coordinate?: string

	// entry-id identifies a specific entry within a referenced Gemara artifact.
	// May be combined with coordinate to identify a sub-location within that entry's output.
	"entry-id"?: string @go(EntryId)

	// digest is a cryptographic hash of the resolved evidence content at collection time,
	// never of the resource identity named by the MappingReference url; format:
	// algorithm:encoded (e.g. sha256:abc123...). It may be omitted when the url is
	// content-addressed and resolves to exactly the evidence bytes, which here means one
	// thing: an oci url pinned by digest (oci://<name>@<algorithm>:<encoded>). A tag-only
	// oci url names whatever the tag points at when it is read, so evidence that cites one
	// without a payload must carry digest, and the AuditLog schema rejects it otherwise.
	// For any other url an absent digest makes no integrity claim.
	digest?: =~"^[a-z0-9]+(?:[+._-][a-z0-9]+)*:[a-zA-Z0-9=_-]+$"

	// remarks is prose regarding this evidence reference
	remarks?: string
}

// _contentAddressedOCI matches an oci url pinned by digest, the one locator form
// treated as content-addressed when an evidence source omits digest. The digest
// grammar is the one the digest field uses.
_contentAddressedOCI: =~"^oci://[^\\s@]+@[a-z0-9]+(?:[+._-][a-z0-9]+)*:[a-zA-Z0-9=_-]+$"

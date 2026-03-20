import * as pulumi from "@pulumi/pulumi";
import * as gcp from "@pulumi/gcp";

const config = new pulumi.Config();
const projectId = config.require("gcp:project");
const region = config.get("gcp:region") || "asia-northeast1";
const serviceName = config.require("serviceName");
const firebaseProjectMode = config.get("firebaseProjectMode") || "existing";
const githubRepo = config.get("githubRepo") || "";

// ============================================================
// Enable required APIs
// ============================================================

const apis = ["run.googleapis.com", "artifactregistry.googleapis.com", "secretmanager.googleapis.com", "iam.googleapis.com"];
const enabledApis = apis.map(
  (api) =>
    new gcp.projects.Service(api, {
      service: api,
      disableOnDestroy: false,
    })
);

// ============================================================
// Artifact Registry
// ============================================================

const repo = new gcp.artifactregistry.Repository("repo", {
  location: region,
  repositoryId: "cloud-run-builds",
  format: "DOCKER",
}, { dependsOn: enabledApis });

// ============================================================
// Service Account
// ============================================================

const sa = new gcp.serviceaccount.Account("cloud-run-sa", {
  accountId: `${serviceName}-sa`,
  displayName: `${serviceName} Cloud Run Service Account`,
});

new gcp.projects.IAMMember("sa-secret-accessor", {
  project: projectId,
  role: "roles/secretmanager.secretAccessor",
  member: pulumi.interpolate`serviceAccount:${sa.email}`,
});

new gcp.projects.IAMMember("sa-firestore-user", {
  project: projectId,
  role: "roles/datastore.user",
  member: pulumi.interpolate`serviceAccount:${sa.email}`,
});

// ============================================================
// Secret Manager
// ============================================================

const geminiApiKeySecret = new gcp.secretmanager.Secret("gemini-api-key", {
  secretId: "gemini-api-key",
  replication: { auto: {} },
}, { dependsOn: enabledApis });

// ============================================================
// Cloud Run
// ============================================================

const service = new gcp.cloudrunv2.Service("app", {
  name: serviceName,
  location: region,
  template: {
    serviceAccount: sa.email,
    containers: [
      {
        image: pulumi.interpolate`${region}-docker.pkg.dev/${projectId}/${repo.repositoryId}/${serviceName}:latest`,
        envs: [
          {
            name: "GEMINI_API_KEY",
            valueSource: {
              secretKeyRef: {
                secret: geminiApiKeySecret.secretId,
                version: "latest",
              },
            },
          },
        ],
        startupProbe: {
          httpGet: { path: "/health" },
        },
      },
    ],
  },
}, { dependsOn: enabledApis });

// Public access
new gcp.cloudrunv2.ServiceIamMember("public", {
  name: service.name,
  location: region,
  role: "roles/run.invoker",
  member: "allUsers",
});

// ============================================================
// Firestore (only when creating new project)
// ============================================================

if (firebaseProjectMode === "new") {
  new gcp.firestore.Database("db", {
    name: "(default)",
    locationId: region,
    type: "FIRESTORE_NATIVE",
  }, { dependsOn: enabledApis });
}

// ============================================================
// Workload Identity Federation (for GitHub Actions)
// ============================================================

const wifPool = new gcp.iam.WorkloadIdentityPool("github-actions", {
  workloadIdentityPoolId: "github-actions",
  displayName: "GitHub Actions",
});

const wifProvider = new gcp.iam.WorkloadIdentityPoolProvider("github", {
  workloadIdentityPoolId: wifPool.workloadIdentityPoolId,
  workloadIdentityPoolProviderId: "github",
  displayName: "GitHub",
  attributeMapping: {
    "google.subject": "assertion.sub",
    "attribute.actor": "assertion.actor",
    "attribute.repository": "assertion.repository",
  },
  oidc: {
    issuerUri: "https://token.actions.githubusercontent.com",
  },
});

if (githubRepo) {
  new gcp.serviceaccount.IAMMember("wif-sa-binding", {
    serviceAccountId: sa.name,
    role: "roles/iam.workloadIdentityUser",
    member: pulumi.interpolate`principalSet://iam.googleapis.com/${wifPool.name}/attribute.repository/${githubRepo}`,
  });
}

// ============================================================
// Exports
// ============================================================

export const cloudRunUrl = service.uri;
export const serviceAccountEmail = sa.email;
export const artifactRegistryRepo = pulumi.interpolate`${region}-docker.pkg.dev/${projectId}/${repo.repositoryId}`;
export const wifProviderName = wifProvider.name;

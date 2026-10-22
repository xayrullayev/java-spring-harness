---
description: TDD loop for Java / Spring Boot — write a failing JUnit 5 test first, implement minimally, refactor, check JaCoCo coverage. Uses the tdd-guide agent and springboot-tdd skill.
---

# Java TDD

Enforce RED → GREEN → REFACTOR for Java / Spring Boot code, using the **tdd-guide** agent and the **springboot-tdd** skill.

Arguments: `$ARGUMENTS` — what to build or fix (e.g. "OrderService.cancel must reject already-shipped orders").

## Step 1: Choose the test slice

| What changes | Test type | Annotation / tooling |
|--------------|-----------|----------------------|
| Pure domain / service logic | Unit | `@ExtendWith(MockitoExtension.class)` |
| MVC controller | Web slice | `@WebMvcTest` + `MockMvc` |
| WebFlux controller | Web slice | `@WebFluxTest` + `WebTestClient` |
| Reactive pipeline | Unit | `StepVerifier` (reactor-test) |
| JPA repository / queries | Data slice | `@DataJpaTest` + Testcontainers |
| External HTTP client | Unit / slice | `MockWebServer` or WireMock |
| Cross-layer flow | Integration | `@SpringBootTest` + Testcontainers |

Prefer the narrowest slice that proves the behavior.

## Step 2: Write the failing test (RED)

```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock OrderRepository orderRepository;
    @InjectMocks OrderService orderService;

    @Test
    @DisplayName("cancel rejects an order that is already shipped")
    void cancel_shippedOrder_throws() {
        when(orderRepository.findById(1L))
            .thenReturn(Optional.of(Order.shipped(1L)));

        assertThatThrownBy(() -> orderService.cancel(1L))
            .isInstanceOf(OrderStateException.class)
            .hasMessageContaining("shipped");
    }
}
```

## Step 3: Run it — it MUST fail for the right reason

```bash
./mvnw -q test -Dtest=OrderServiceTest            # Maven
./gradlew test --tests 'OrderServiceTest'          # Gradle
```

A compile error is not a valid RED — add the minimal signature first so the test fails on the assertion.

## Step 4: Minimal implementation (GREEN)

Write only enough production code to pass. Re-run the single test, then the module's suite.

## Step 5: Refactor

Clean up with tests green: extract methods, use records, remove duplication. Re-run tests after each step.

## Step 6: Coverage

```bash
./mvnw -q test jacoco:report && open target/site/jacoco/index.html
./gradlew test jacocoTestReport
```

Target: 80%+ line coverage on changed service / domain classes. Do not chase coverage on config classes, DTOs, or generated code.

## Reactive example (WebFlux / Reactor)

```java
@Test
void findBalance_downstreamTimeout_fallsBackToCached() {
    when(absClient.getBalance("ACC1")).thenReturn(Mono.never());
    when(cache.get("ACC1")).thenReturn(Mono.just(new Balance("ACC1", BigDecimal.TEN)));

    StepVerifier.withVirtualTime(() -> service.findBalance("ACC1"))
        .thenAwait(Duration.ofSeconds(5))
        .assertNext(b -> assertThat(b.amount()).isEqualByComparingTo("10"))
        .verifyComplete();
}
```

## Related

- Agent: `tdd-guide`
- Skills: `springboot-tdd`, `tdd-workflow`, `springboot-verification`
- Rules: `rules/java/testing.md`
